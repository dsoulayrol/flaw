-- flaw, a Lua OO management framework for Awesome WM widgets.
-- Copyright (C) 2009, 2010 David Soulayrol <david.soulayrol AT gmail DOT net>

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


local lfs = require('lfs')

local naughty = require('naughty')

-- Helper tools for environment settings.
function load_battery_support()
   local mod = nil
   local path = '/sys/class/power_supply'
   for file in lfs.dir(path) do
      if file ~= "." and file ~= ".." then
         local f = io.open(path .. '/' .. file .. '/type')
         if f ~= nil then
            if f:read() == 'Battery' then
               mod = require('flaw.battery')
            end
            f:close()
         end
      end
      if mod ~= nil then break end
   end
   return mod
end

function load_alsa_support()
   -- TODO load this only if necessary.
   -- return require('flaw.alsa')
   return nil
end

-- Essential modules.
local gadget = require('flaw.gadget')
local provider = require('flaw.provider')
local event = require('flaw.event')
local helper = require('flaw.helper')

-- Implementation modules.
local cpu = require('flaw.cpu')
local gmail = require('flaw.gmail')
local memory = require('flaw.memory')
local network = require('flaw.network')

-- Load only the following modules if necessary hardware element or
-- software package is present.
local alsa = load_alsa_support()
local battery = load_battery_support()


--- The fully loaded awesome package.
--
-- <p><b>flaw</b> package is composed of core modules, which provide
-- the raw mechanisms and utilities, and implementation modules which
-- build upon this core to propose interesting gadgets and
-- information.</p>
--
-- <p>Hereafter are described the common use cases that <b>flaw</b>
-- tries to address. Users also should have a look at the
-- implementation modules they are interested in. Developers may read
-- the core modules documentation before doing more complicated
-- things.</p>
--
-- <h2>The gadgets</h2>
--
-- <p>Gadgets are a wrapper around awesome widgets that provide an
-- automated way to react asynchronously on some hardware or software
-- events. The <a
-- href="<%=luadoc.doclet.html.module_link('flaw.gadget', doc)%>"
-- >gadget</a> core module provides the main display objects factory
-- and management.</p>
--
-- <p>Creating a gadget is straight forward. <b>flaw</b> provides a
-- unique factory to build any kind of gadget, and its arguments are
-- always the same, whatever the situation. Here is a moderately
-- complicated example which builds a CPU graph widget.</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.cpu.graph', 'cpu',<br/>
-- &nbsp;&nbsp;&nbsp;{ delay = 5 } ,<br/>
-- &nbsp;&nbsp;&nbsp;{ width = '35',<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;height = '0.8',<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;grow = 'right',<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;max_value = '100' })<br/>
-- </div>
--
-- <p>The first two arguments are the type and the name of the
-- widget. You will learn what to provide in the type field by reading
-- the appropriate module documentation. The name of the gadget also
-- can be important for some modules, since it can be used to identify
-- a resource for example.</p>
--
-- <p>The next parameter is a table providing properties for the
-- gadget to create. Again, modules documentation will provide
-- information on the available properties. Note that the
-- <code>delay</code> provides the gadget refresh period and is
-- available to all of them. It defaults to 10 seconds if omitted.</p>
--
-- <p>The last parameter is another table providing properties for the
-- wrapped widget. These are detailed in the awesome
-- documentation.</p>
--
-- <h3>Icon Gadgets</h3>
--
-- <p>Icon gadgets wrap the <i>imagebox</i> widget from awesome. They
-- can display an image and that's all, which makes them the simpler
-- gadget provided by <b>flaw</b>. What's interesting about them
-- though is that like any other gadget they rely on one provider and
-- can make use of events.</p>
--
-- <p>Assuming the beautiful property <code>battery_icon</code> is the
-- path to a default battery icon path, the following statement
-- creates a new battery status icon gadget. Note the
-- <code>image</code> widget property which is explained in awesome
-- documentation.</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.battery.imagebox', 'BAT0',<br/>
-- &nbsp;&nbsp;&nbsp;{}, { image = image(beautiful.battery_icon) })<br/>
-- </div>
--
-- <h3>Text Gadgets</h3>
--
-- <p>Text gadgets allow you to display any textual information. What
-- makes them really interesting is that the display can be used to
-- format information returned by the provider associated to the
-- gadget.</p>
--
-- <p>All text gadgets provide a default content related to the
-- information they gather from the provider (percents of available
-- memory, or of battery load for example). To customize the gadget
-- display, you can provide the <code>pattern</code> gadget option to
-- the factory. Note in the following example that the last argument
-- table (the widget options table) is omitted since it is empty.</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.alsa.textbox', '0',<br/>
-- &nbsp;&nbsp;&nbsp;{ pattern = '&lt;span color="#ffffff"&gt;
-- $volume&lt;/span&gt;%($mute)' })
-- </div>
--
-- <p>The variables to be formatted must be prefixed by a dollar
-- sign. The available variables are detailed in the providers
-- documentations.</p>
--
-- <h3>Graph Gadgets</h3>
--
-- <p>Graph gadgets are an interesting way to represent data variation
-- in the time. All graph gadgets provide default content to be
-- drawn. To customize the gadget display, you can provide the
-- <code>values</code> gadget option to the factory.</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.memory.graph', '', {}, {<br/>
-- &nbsp;&nbsp;&nbsp;width = '35',<br/>
-- &nbsp;&nbsp;&nbsp;height = '0.8',<br/>
-- &nbsp;&nbsp;&nbsp;grow = 'right',<br/>
-- &nbsp;&nbsp;&nbsp;bg = beautiful.bg_normal,<br/>
-- &nbsp;&nbsp;&nbsp;fg = beautiful.fg_normal,<br/>
-- &nbsp;&nbsp;&nbsp;max_value = '100',<br/>
-- })
-- </div>
--
-- <h2>Providers</h2>
--
-- <p>Providers are the objects that gather data to feed a gadget. The
-- <a href="<%=luadoc.doclet.html.module_link('flaw.provider', doc)%>"
-- >provider</a> core module provides the roots of the data mining
-- objects.</p>
--
-- <p>Creating a gadget automatically registers itself to a provider
-- so that the displayed information is refreshed at the requested
-- pace. Providers can be shared among gadgets, and only refresh their
-- data accordingly to the smallest gadget refresh rate.</p>
--
-- <p>No user action is required for this mechanism. However, the
-- refresh rate of a gadget can be tuned using the <code>delay</code>
-- gadget option. As seen in the gadgets description above, it
-- defaults to 10 seconds.</p>
--
-- <h2>Events</h2>
--
-- <p>The automated and intelligent refresh loop of <b>flaw</b> is the
-- core of its design, but gadgets would be rather dumb if that was
-- all. Events were introduced to provide the capability to react to
-- some data values, beyond simply displaying them. The <a
-- href="<%=luadoc.doclet.html.module_link('flaw.event', doc)%>"
-- >event</a> core module proposes this asynchronous event mechanism
-- which is available to all the gadgets.</p>
--
-- <p>Events are made of a trigger and an action. The trigger is an
-- object which takes a condition and provides some status depending
-- of its type. The event trigger is tested each time the gadget's
-- provider refreshes its data, and the action called if the trigger
-- is activated. The condition function accepts the data table updated
-- by the provider as parameter. This table layout depends on the
-- provider and is detailed in the provider documentation. It shall
-- return true to fire the event, or false otherwise.</p>
--
-- <p>The action function takes the gadget as parameter. It can do
-- absolutely anything, and its return value has no meaning for
-- <b>flaw</b>.</p>
--
-- <p>Assuming <code>g</code> is a battery icon gadget created as
-- above and <code>battery_low_icon</code> a beautiful property
-- holding the path to an explicit low battery icon, here is a short
-- snippet to change the icon in a gadget when the battery load gets
-- really low.</p>
--
-- <div class='example'>
-- g.add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.LatchTriger:new{
-- condition = function(d) return d.load &lt; 9 end },<br/>
-- &nbsp;&nbsp;&nbsp;function(g) g.widget.image =
-- image(beautiful.battery_low_icon) end)
-- </div>
--
-- <p>It is important to carefully choose the correct trigger for the
-- event to be raised. The <a
-- href='flaw.event.html#LatchTrigger'><code>LatchTrigger</code></a>
-- object used here will make the event happen only at the moment the
-- load gets under 9 percents. If the percentage of load remains under
-- 9, the event will not be triggered again. If a raw <a
-- href='flaw.event.html#Trigger'><code>Trigger</code></a> object had
-- been used, the event would be triggered again at each provider's
-- refresh.</p>
--
-- <p> If a repeated refresh can be considered as a minor optimisation
-- issue here, it can become a really annoying problem, like in the
-- following sample where <b>naughty</b> is used to be notified if the
-- same situation.</p>
--
-- <div class='example'>
-- g.add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.LatchTriger:new{
-- condition = function(d) return d.load &lt; 9 end },<br/>
-- &nbsp;&nbsp;&nbsp;function(g) naughty.notify{<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;title = "Battery Warning",<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;text = "Battery low! " .. g.provider.data.load .. "% left!",<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;timeout = 5,<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;position = "top_right",<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;fg = beautiful.fg_focus,<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;bg = beautiful.bg_focus} end)
-- </div>
--
-- <p>Here is another example which introduces the <a
-- href='flaw.event.html#EdgeTrigger'><code>EdgeTrigger</code></a>. This
-- trigger is activated when the condition's state change, that is if
-- it becomes true or if it becomes false. Since <b>Lua</b> objects
-- can be extended at will, the following snippet also moves the
-- refresh action content into a <code>my_update</code> object's
-- member. This way, behaviour which is common to multiple events can
-- be written only once.</p>
--
-- <div class='example'>
-- bg = flaw.gadget.new('flaw.battery.imagebox', 'BAT0',<br/>
-- &nbsp;&nbsp;&nbsp;{<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my_icons = {<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;image(
-- beautiful.icon_battery_low ),<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;image(
-- beautiful.icon_battery_mid ),<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;image(
-- beautiful.icon_battery_full )<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my_load_icon = image(
-- beautiful.icon_battery_plugged ),<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my_update = function(self)<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;if
-- self.provider.data.st_symbol == flaw.battery.STATUS_CHARGING then<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.widget.image
-- = self.my_load_icon<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;else<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;self.widget.image
-- = self.my_icons[math.floor(self.provider.data.load / 30) + 1]<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br/>
-- &nbsp;&nbsp;&nbsp;}, {<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;image
-- = image(beautiful.icon_battery_full)<br/>
-- &nbsp;&nbsp;&nbsp;} )<br/>
-- <br/>bg:add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.EdgeTrigger:new{
-- condition = function(d) return d.load < 60 end },<br/>
-- &nbsp;&nbsp;&nbsp;function (g) g:my_update() end )<br/>
-- bg:add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.EdgeTrigger:new{
-- condition = function(d) return d.load < 30 end },<br/>
-- &nbsp;&nbsp;&nbsp;function (g) g:my_update() end )<br/>
-- bg:add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.EdgeTrigger:new{<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;condition
-- = function(d) return d.st_symbol == flaw.battery.STATUS_CHARGING end },<br/>
-- &nbsp;&nbsp;&nbsp;function (g) g:my_update() end )<br/>
-- </div>
--
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module("flaw")

--- Notify the user.
--
-- <p>This function pops up a notification displaying a list of
-- modules which were not loaded. These checked modules are those
-- which depend on hardware or sources that can be absent from some
-- system, like the battery.</p>
--
-- <p>This function can typically be called at the end of the
-- configuration file, or on demand to check the flaw library status.</p>
function check_modules()
   local dropped_modules = ''
   if alsa == nil then dropped_modules = 'alsa\n' end
   if battery == nil then dropped_modules = dropped_modules .. 'battery\n' end
   if dropped_modules ~= '' then
      naughty.notify{
         title = "Flaw",
         text = "The following modules are absent from your system:\n"
            .. dropped_modules,
         timeout = 12,
         position = "top_right"}
   end
end
