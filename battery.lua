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
local tonumber = tonumber

local beautiful = require('beautiful')
local naughty = require('naughty')

local flaw = {
   helper = require('flaw.helper'),
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider')
}


--- Battery information gadgets and provider.
--
-- <br/><br/>
-- This module contains a provider for battery information and two
-- gadgets: a text gadget and an icon gadget.
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
--
-- </p><h2>Icon Gadget</h2><p>
--
-- Assuming you have created a beautiful property to store your
-- battery icon path, simply add the following line to your
-- configuration to create a battery status icon gadget.<br/>
--
-- <code>g = flaw.gadget.new('flaw.battery.imagebox', 'BAT0', </code><br/>
-- <code>&nbsp;&nbsp;&nbsp;{}, { image = image(beautiful.battery_icon) })</code>
--
-- <br/><br/>
-- The battery status icon gadget specializes the standard icon gadget
-- to use the <i>battery</i> module provider and that's all. The main
-- interest of this comes with the use of events.  Let's say you want
-- to change the icon to visualize roughly the power left on the
-- battery. You can add an <a href='flaw.event.html'>event</a> to the
-- icon gadget to launch an action when the battery load reaches a
-- given value.<br/>
--
-- <code>g.add_event(</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;flaw.event.LatchTriger:new{
-- condition = function(d) return d.load < 25 end },</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;function(g) g.widget.image =
-- image(beautiful.battery_low_icon) end)</code>
--
-- <br/><br/>
-- The condition you provide is called with the provider data as
-- argument. The action is called with the gadget as argument. Note
-- that the use of a <a
-- href='flaw.event.html#LatchTrigger'><code>LatchTrigger</code></a>
-- will make the event happen only at the moment the load gets under
-- 25 percents.
--
-- <br/><br/>
-- Here is another example to be notified if the battery load gets
-- really low.<br/>
--
-- <code>g.add_event(</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;flaw.event.LatchTriger:new{
-- condition = function(d) return d.load < 10 end },</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;function(g) naughty.notify{</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;title = "Battery Warning",</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;text = "Battery low! " .. g.provider.data.load .. "% left!",</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;timeout = 5,</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;position = "top_right",</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fg = beautiful.fg_focus,</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;bg = beautiful.bg_focus} end)</code>
--
-- </p><h2>Text Gadget</h2><p>
--
-- The battery status text gadget allows you to configure the display
-- of the raw provider data. By default, the gadget pattern is
-- <code>'$load% $status'</code>.
--
-- <br/><br/>
-- To create such a gadget, add the following line to your
-- configuration.<br/>
--
-- <code>g = flaw.gadget.new('flaw.battery.textbox', 'BAT0')</code>
--
-- <br/><br/>
-- If you want to provide your own pattern, add the pattern gadget
-- option:<br/>
--
-- <code>g = flaw.gadget.new('flaw.battery.textbox', 'BAT0',</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;{ pattern = '&lt;span color="#ffffff"&gt;
-- $load&lt;/span&gt;%' })</code>
module('flaw.battery')


-- Battery statuses.
STATUS_UNKNOWN = '='
STATUS_PLUGGED = '(A/C)'
STATUS_CHARGING = '^'
STATUS_DISCHARGING = 'v'

--- The battery provider prototype.
--
-- <br/><br/>
-- The battery provider type is set to battery._NAME. Its status data
-- are read from the files found under
-- <code>/sys/class/power_supply/&lt;BAT_ID&gt;</code>.
--
-- <br/><br/>
-- The battery provider data is composed of two fields.
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
-- @class table
-- @name BatteryProvider
BatteryProvider = flaw.provider.Provider:new{ type = _NAME }
BatteryProvider.data.load = '0'
BatteryProvider.data.status = ''

--- Callback for provider refresh.
function BatteryProvider:do_refresh()
   local load
   local fcur = io.open("/sys/class/power_supply/" .. self.id .. "/charge_now")
   local fcap = io.open("/sys/class/power_supply/" .. self.id .. "/charge_full")
   if fcur ~= nil and fcap ~= nil then
      load = math.floor(fcur:read() * 100 / fcap:read())
      if load > 100 then load = 100 end
      fcur:close()
      fcap:close()
   end

   local f_status = io.open("/sys/class/power_supply/" .. self.id .. "/status")
   local raw_status
   if f_status ~= nil then
      raw_status = f_status:read()
      f_status:close()
   end

   local status = STATUS_PLUGGED

   if raw_status:match("Charging") then
      status = STATUS_CHARGING
   elseif raw_status:match("Discharging") then
      status = STATUS_DISCHARGING
   end

   self.data.load = load
   self.data.status = status
end

--- A factory for battery providers.
--
-- <br/><br/>
-- Only one provider is built for a slot. Created providers are stored
-- in the global provider cache.
--
-- @param  slot the identifier of the battery for which the new
--         provider should gather information
-- @return a brand new battery provider, or an existing one if the
--         given slot was already used to create one.
function BatteryProviderFactory(slot)
   local p = flaw.provider.get(_NAME, slot)
   -- Create the provider if necessary.
   if p == nil then
      p = BatteryProvider:new{ id = slot }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget prototype for battery status display.
flaw.gadget.register(
   flaw.gadget.TextGadget:new{ type = _NAME .. '.textbox' },
   BatteryProviderFactory,
   { pattern = '$load% $status' }
)

-- An icon gadget prototype for battery status display.
flaw.gadget.register(
   flaw.gadget.IconGadget:new{ type = _NAME .. '.imagebox' },
   BatteryProviderFactory,
   { status = STATUS_UNKNOWN }
)
