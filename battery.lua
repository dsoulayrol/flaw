-- flaw, a Lua OO management framework for Awesome WM widgets.
-- Copyright (C) 2009,2010,2011 David Soulayrol <david.soulayrol AT gmail DOT net>

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.


-- Grab environment.
local io = io
local math = math
local os = os

local beautiful = require('beautiful')
local naughty = require('naughty')

local flaw = {
   helper = require('flaw.helper'),
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider')
}


--- Battery information gadgets and provider.
--
-- <p>This module contains a provider for battery information and two
-- gadgets: a text gadget and an icon gadget.</p>
--
-- <h2>Gadgets</h2>
--
-- <p>The ID of the gadget designates the battery slot to be
-- monitored. Battery gadgets provide no custom parameters. See the <a
-- href="flaw.gadget.html">gadget</a> module documentation to learn
-- about standard gadgets parameters.</p>
--
-- <h3>Icon Gadget</h3>
--
-- <p>The battery icon gadget can be instantiated by indexing the
-- gadget module with <code>icon.battery</code>. Here is an exemple
-- which assumes the battery icon path is stored in a <b>beautiful</b>
-- property.</p>
--
-- <div class='example'>
-- g = flaw.gadget.icon.battery(<br/>
-- &nbsp;&nbsp;&nbsp;'BAT0', {}, { image = image(beautiful.battery_icon) })<br/>
-- </div>
--
-- <h3>Text Gadget</h3>
--
-- <p>The battery text gadget can be instantiated by indexing the
-- gadget module with <code>text.battery</code>. By default, the
-- gadget pattern is <code>'$load% $status'</code>. See the provider's
-- documentation below to learn about the available variables.</p>
--
-- <div class='example'>
-- g = flaw.gadget.text.battery('BAT0')
-- </div>
--
-- <h2>Provider</h2>
--
-- <p>The battery provider loads its information from
-- <code>/proc/acpi/battery/&lt;ID&gt;/</code> and
-- <code>/sys/class/power_supply/&lt;ID&gt;/</code> if they exist.</p>
--
-- <p>The battery provider data is composed of the following fields.</p>
--
-- <ul>
--
-- <li><code>load</code>
--
-- <p>The current battery load in percents.</p></li>
--
-- <li><code>st_symbol</code>
--
-- <p>The current power supply utilisation. It is set to the value of
-- <code>battery.STATUS_PLUGGED</code> if AC adaptor is in use and
-- there is no activity on the battery,
-- <code>battery.STATUS_CHARGING</code> if the battery is in charge,
-- or <code>battery.STATUS_DISCHARGING</code> if the battery is
-- currently the only power supply. At last, the symbol
-- <code>battery.STATUS_UNKNOWN</code> is used when the provider has
-- no information on the battery slot.</p></li>
--
-- <li><code>seconds</code>
--
-- <p>The number of seconds until the battery is empty or loaded,
-- whether its status is discharging or charging. This information is
-- currently only available if the
-- <code>/proc/acpi/battery/&lt;ID&gt;/</code> path is
-- available</p></li>
--
-- <li><code>time</code>
--
-- <p>The <code>seconds</code> information, formatted as a date.</p></li>
--
-- </ul>
--
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009,2010,2011 David Soulayrol
module('flaw.battery')


-- Battery statuses.
STATUS_UNKNOWN = '='
STATUS_PLUGGED = '(A/C)'
STATUS_CHARGING = '^'
STATUS_DISCHARGING = 'v'

--- The battery provider prototype.
--
-- <p>The battery provider type is set to
-- <code>battery._NAME</code>.</p>
--
-- @class table
-- @name BatteryProvider
BatteryProvider = flaw.provider.CyclicProvider:new{ type = _NAME }

--- Load state information from
--- <code>/proc/acpi/battery/&lt;ID&gt;/</code> if it exists.
function BatteryProvider:load_from_procfs()
   local r = false
   local p = self.data.proc

   r = flaw.helper.file.load_state_file(
      '/proc/acpi/battery/' .. self.id:upper(), 'state', p)
   r = flaw.helper.file.load_state_file(
      '/proc/acpi/battery/' .. self.id:upper(), 'info', p) and r

   if r then
      -- Adapt values.
      local state = p.state_charging_state or ''
      local r_capacity = p.state_remaining_capacity:match('(%d+).*') or 0
      local rate = p.state_present_rate:match('(%d+).*') or 1

      if rate ~= nil and rate ~= 0 then
         if state == 'discharging' then
            -- remaining seconds.
            self.data.seconds = 3600 * r_capacity / rate
            self.data.time = os.date('!remaining %X', self.data.seconds)
         elseif state == 'charging' then
            -- seconds until charged.
            local l_capacity = p.info_last_full_capacity:match('(%d+).*') or 0
            self.data.seconds = 3600 * (l_capacity - r_capacity) / rate
            self.data.time = os.date('!full in %X', self.data.seconds)
         end
      end
   end
end

--- Load state information from
--- <code>/sys/class/power_supply/&lt;ID&gt;/</code> if it exists.
function BatteryProvider:load_from_sysfs()
   local f = nil

   -- Load raw values.
   local f = io.open("/sys/class/power_supply/" .. self.id .. "/charge_now")
   if f ~= nil then
      self.data.sys.charge_now = f:read()
      f:close()
   end

   f = io.open("/sys/class/power_supply/" .. self.id .. "/charge_full")
   if f ~= nil then
      self.data.sys.charge_full = f:read()
      f:close()
   end

   f = io.open("/sys/class/power_supply/" .. self.id .. "/status")
   if f ~= nil then
      self.data.sys.status = f:read()
      f:close()
   end

   -- Compute interesting values.
   self.data.load =
      math.floor(self.data.sys.charge_now * 100 / self.data.sys.charge_full)
   if self.data.load > 100 then self.data.load = 100 end

   self.data.st_symbol = STATUS_PLUGGED

   if self.data.sys.status:match("Charging") then
      self.data.st_symbol = STATUS_CHARGING
   elseif self.data.sys.status:match("Discharging") then
      self.data.st_symbol = STATUS_DISCHARGING
   end
end

--- Callback for provider refresh.
function BatteryProvider:do_refresh()
   -- TODO: Do elect the method to call.
   self:load_from_sysfs()
   self:load_from_procfs()
end

--- A factory for battery providers.
--
-- <p>Only one provider is built for a slot. Created providers are
-- stored in the global provider cache.</p>
--
-- @param  slot the identifier of the battery for which the new
--         provider should gather information.
-- @return a brand new battery provider, or an existing one if the
--         given slot was already used to create one.
function provider_factory(slot)
   local p = flaw.provider.get(_NAME, slot)
   -- Create the provider if necessary.
   if p == nil then
      p = BatteryProvider:new{
         id = slot, data = {
            load = 0,
            st_symbol = '',
            seconds = 0,
            time = '',
            sys = {}, proc = {} } }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget prototype for battery status display.
flaw.gadget.register.text(_M, { pattern = '$load% $status' })

-- An icon gadget prototype for battery status display.
flaw.gadget.register.icon(_M, { status = STATUS_UNKNOWN })
