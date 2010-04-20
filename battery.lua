-- flaw, a Lua OO management framework for Awesome WM widgets.
-- Copyright (C) 2009 David Soulayrol <david.soulayrol AT gmail DOT net>

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
-- <h2>Icon Gadget</h2>
--
-- <p>Assuming you have created a beautiful property to store your
-- battery icon path, simply add the following line to your
-- configuration to create a battery status icon gadget.</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.battery.imagebox', 'BAT0',<br/>
-- &nbsp;&nbsp;&nbsp;{}, { image = image(beautiful.battery_icon) })<br/>
-- </div>
--
-- <p>The battery status icon gadget specializes the standard icon
-- gadget to use the <i>battery</i> module provider and that's
-- all. The main interest of this comes with the use of events.  Let's
-- say you want to change the icon to visualize roughly the power left
-- on the battery. You can add an <a href='flaw.event.html'>event</a>
-- to the icon gadget to launch an action when the battery load
-- reaches a given value.</p>
--
-- <div class='example'>
-- g.add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.LatchTriger:new{<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;condition = function(d) return d.load &lt; 25 end },<br/>
-- &nbsp;&nbsp;&nbsp;function(g) g.widget.image =
-- image(beautiful.battery_low_icon) end)
-- </div>
--
-- <p>The condition you provide is called with the provider data as
-- argument. The action is called with the gadget as argument. Note
-- that the use of a <a
-- href='flaw.event.html#LatchTrigger'><code>LatchTrigger</code></a>
-- will make the event happen only at the moment the load gets under
-- 25 percents.</p>
--
-- <p>Here is another example to be notified if the battery load gets
-- really low.</p>
--
-- <div class='example'>
-- g.add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.LatchTriger:new{
-- condition = function(d) return d.load &lt; 10 end },<br/>
-- &nbsp;&nbsp;&nbsp;function(g) naughty.notify{<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;title = "Battery Warning",<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;text = "Battery low! " .. g.provider.data.load .. "% left!",<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;timeout = 5,<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;position = "top_right",<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fg = beautiful.fg_focus,<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;bg = beautiful.bg_focus} end)
-- </div>
--
-- <h2>Text Gadget</h2>
--
-- <p>The battery status text gadget allows you to configure the
-- display of the raw provider data. By default, the gadget pattern is
-- <code>'$load% $status'</code>.</p>
--
-- <p>To create such a gadget, add the following line to your
-- configuration.</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.battery.textbox', 'BAT0')
-- </div>
--
-- <p>If you want to provide your own pattern, add the pattern gadget
-- option:</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.battery.textbox', 'BAT0',<br/>
-- &nbsp;&nbsp;&nbsp;{ pattern = '&lt;span color="#ffffff"&gt;
-- $load&lt;/span&gt;%' })
-- </div>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module('flaw.battery')


-- Battery statuses.
STATUS_UNKNOWN = '='
STATUS_PLUGGED = '(A/C)'
STATUS_CHARGING = '^'
STATUS_DISCHARGING = 'v'

--- The battery provider prototype.
--
-- <p>The battery provider type is set to battery._NAME. Its status
-- data are read from the files found under
-- <code>/sys/class/power_supply/&lt;BAT_ID&gt;</code>.</p>
--
-- <p>The battery provider data is composed of two fields.</p>
--
-- <ul>
-- <li><code>load</code><br/>
-- The current battery load in percents.</li>
-- <li><code>status</code><br/>
-- presents the current power supply utilisation. Its value can be
-- <code>STATUS_PLUGGED</code> if AC adaptor is in use and there is no
-- activity on the battery, <code>STATUS_CHARGING</code> if the
-- battery is in charge, or <code>STATUS_DISCHARGING</code> if the
-- battery is currently the only power supply.</li>
-- </ul>
--
-- @class table
-- @name BatteryProvider
BatteryProvider = flaw.provider.CyclicProvider:new{ type = _NAME }

--- Load state information from /proc/acpi/battery/&lt;ID&gt;/state if it exists
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

--- Load state information from /proc/acpi/battery/&lt;ID&gt;/state if it exists
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
--         provider should gather information
-- @return a brand new battery provider, or an existing one if the
--         given slot was already used to create one.
function BatteryProviderFactory(slot)
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
flaw.gadget.register(
   'BatteryTextbox', flaw.gadget.TextGadget:new{}, BatteryProviderFactory,
   { pattern = '$load% $status' })

-- An icon gadget prototype for battery status display.
flaw.gadget.register(
   'BatteryIcon', flaw.gadget.IconGadget:new{}, BatteryProviderFactory,
   { status = STATUS_UNKNOWN })
