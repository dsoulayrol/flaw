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
   -- TODO: load this only if amixer, the ALSA subsytem and at least
   -- one card are present.
   return require('flaw.alsa')
end

-- Essential modules.
local gadget = require('flaw.gadget')
local provider = require('flaw.provider')
local event = require('flaw.event')
local helper = require('flaw.helper')

-- Service modules.
local calendar = require('flaw.calendar')
local cpu = require('flaw.cpu')
local gmail = require('flaw.gmail')
local memory = require('flaw.memory')
local network = require('flaw.network')
local title = require('flaw.title')

-- Load only the following modules if necessary hardware element or
-- software package is present.
local alsa = load_alsa_support()
local battery = load_battery_support()


--- Introduction to the core concepts and mechanisms.
--
-- <p>The <b>flaw</b> package is composed of core modules which
-- provide the raw mechanisms and utilities, and service modules which
-- build upon this core to propose interesting gadgets with their
-- associated information sources.</p>
--
-- <p>Hereafter are described the core concepts developed by
-- <b>flaw</b>. Users also should have a look at the service modules
-- they are interested in. Developers may read the core modules
-- documentation before doing more complicated things.</p>
--
-- <h2>Setup</h2>
--
-- <p>The following statement must be inserted in the <b>awesome</b>
-- configuration before any <b>flaw</b> gadget or mechanism can be
-- used. Such a statement is usually written at the top of the
-- configuration file, where <b>naughty</b>, <b>beautiful</b> or
-- others modules are declared.</p>
--
-- <div class='example'>
-- require('flaw')<br/>
-- </div>
--
-- <p>When this statement is parsed at start up, each of the non-core
-- modules referenced in <b>flaw</b>'s <code>init.lua</code> are
-- loaded and then register the gadgets they provide, and a factory
-- for their associated provider. All this information is maintained
-- in a table in the <a href="flaw.gadget.html">gadget</a> core
-- module, and is ready to be used to instantiate gadgets.</p>
--
-- <h2>Gadgets</h2>
--
-- <p>Gadgets are a wrapper around <b>awful</b> widgets that provide
-- an automated way to react asynchronously on some hardware or
-- software events. The <a href="flaw.gadget.html">gadget</a> core
-- module provides the main gadgets factory and management.</p>
--
-- <p>Gadgets are divided in types which are named after the kinds of
-- widgets <b>awesome</b> provides: <code>Text</code>,
-- <code>Icon</code>, <code>Graph</code> and <code>ProgressBar</code>
-- (which is reduced to <code>Bar</code> in <b>flaw</b>). Thanks to
-- some nifty tricks, creating a gadget is straight forward. As an
-- example, the following statement instantiates a very simple gadget
-- which displays the title of the focused window.
--
-- <div class='example'>
-- gtitle = flaw.gadget.text.title('')
-- </div>
--
-- <p>The <a href="flaw.gadget.html">gadget</a> module is indexed
-- first with the type of the desired gadget, and then with its
-- name. <code>title</code> is actually one of the service modules
-- which were loaded at start up, and which have registered a
-- <code>Text</code> gadget. Note that the parameter is required,
-- while not useful to this gadget (hence the empty string).</p>
--
-- <p>Here is a moderately complicated example which builds an
-- <b>awful</b> 60x18 graph widget which is updated every 5 seconds
-- with the current CPU activity.</p>
--
-- <div class='example'>
-- gcpu = flaw.gadget.graph.cpu('cpu',<br/>
-- &nbsp;&nbsp;&nbsp;{ delay = 5 }, { width = 60, height = 18 })<br/>
-- </div>
--
-- <p>The <a href="flaw.gadget.html">gadget</a> module is indexed
-- first with the <code>graph</code> type, and then with the
-- <code>cpu</code> gadget name. Indeed, the <code>cpu</code> module
-- registers a <code>Text</code>, a <code>Graph</code> and an
-- <code>Icon</code> gadget when loaded. Here the required first
-- parameter designates the cpu to be monitored. The second and third
-- parameters are respectively the gadget and the wrapped widget
-- options.</p>
--
-- <p>Here is now how these two gadgets can be embedded in a
-- <i>wibox</i> with a layout box and a tags list.</p>
--
-- <div class='example'>
-- for s = 1, screen.count() do<br/>
-- &nbsp;&nbsp;&nbsp;mylayoutbox[s] = awful.widget.layoutbox(s)<br/>
-- &nbsp;&nbsp;&nbsp;mytaglist[s] = awful.widget.taglist(<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;s, awful.widget.taglist.label.all, mytaglist.buttons))<br/>
-- &nbsp;&nbsp;&nbsp;mywibox[s] = awful.wibox({ position = "top", screen = s })<br/>
-- &nbsp;&nbsp;&nbsp;<br/>
-- &nbsp;&nbsp;&nbsp;-- Add widgets to the wibox - order matters<br/>
-- &nbsp;&nbsp;&nbsp;mywibox[s].widgets = {<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;{<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;mytaglist[s],<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gcpu.widget,<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;gtitle.widget,<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;layout = awful.widget.layout.horizontal.leftright<br/>
-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;},<br/>
-- &nbsp;&nbsp;&nbsp;mylayoutbox[s],<br/>
-- &nbsp;&nbsp;&nbsp;layout = awful.widget.layout.horizontal.rightleft<br/>
-- &nbsp;&nbsp;&nbsp;}<br/>
-- end<br/>
-- </div>
--
-- <h2>Providers</h2>
--
-- <p>Providers are the objects that gather data to feed a gadget. The
-- <a href="flaw.provider.html">provider</a> core module provides the
-- roots of the data mining objects.</p>
--
-- <p>Creating a gadget automatically registers itself to a provider
-- so that the displayed information is refreshed at the requested
-- pace. Providers can be shared among gadgets, and only refresh their
-- data according to the smallest gadget refresh rate.</p>
--
-- <p>No user action is required for this mechanism. However, the
-- refresh rate of a gadget can be tuned using the <code>delay</code>
-- gadget option. As seen in the gadgets description above, it
-- defaults to 10 seconds.</p>
--
-- <h2>Events</h2>
--
-- <p>The automated and efficient refresh loop of <b>flaw</b> is the
-- core of its design. It provides cyclic data updates to gadgets
-- which display it in accordance with their type. Events were
-- introduced to provide the capability to react to some data values,
-- and to do something else than just displaying them. This mechanism
-- is available to all of gadgets and is implemented in the <a
-- href="flaw.event.html">event</a> core module.</p>
--
-- <p>Events are made of a trigger and an action. The trigger's
-- condition takes the provider's data and is tested each time a
-- refresh is called. If it returns true, the event's action is then
-- fired, with the gadget as parameter. It can do absolutely anything,
-- and its return value has no meaning for <b>flaw</b>.</p>
--
-- <p>Here is an example assuming <code>g</code> is a battery icon
-- gadget and <code>battery_low_icon</code> a beautiful property
-- holding the path to an explicit low battery icon. This snippet
-- changes of the gadget when the battery load gets really low.</p>
--
-- <div class='example'>
-- g.add_event(<br/>
-- &nbsp;&nbsp;&nbsp;flaw.event.LatchTriger:new{
-- condition = function(d) return d.load &lt; 9 end },<br/>
-- &nbsp;&nbsp;&nbsp;function(g) g.widget.image =
-- image(beautiful.battery_low_icon) end)
-- </div>
--
-- <h2>Writing a new service module</h2>
--
-- <p><b>FIXME</b></p>
--
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009,2011,2011, David Soulayrol
module("flaw")

--- Notify the dropped service modules to the user.
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
