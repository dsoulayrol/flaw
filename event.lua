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
local setmetatable = setmetatable


--- Events handling for <b>flaw</b>.
--
-- <br/><br/>
-- Events are a way for the user to modify the gadget behaviour or
-- properties when certain conditions are met. An event is composed of
-- a trigger, which computes the condition, and an action.
--
-- <br/><br/>
-- Condition and action are written by the user. Events are registered
-- to a gadget, which in turns register the trigger to its
-- provider. The event trigger is tested each time the provider
-- refreshes its data, and the action called if the trigger is
-- activated.
--
-- <br/><br/>
-- The condition function accepts one parameter which is the data
-- table updated by the provider. It shall return true to fire the
-- event, or false otherwise. The action function takes the gadget as
-- parameter. Its return value is dropped.
--
-- <br/><br/><b>Example:</b><br/>
-- <code>t = flaw.event.LatchTrigger:new{</code><br/>
-- <code>&nbsp;&nbsp;&nbsp;condition = function(d) return d.load < 25 end }</code><br/>
-- <code>a = function(g) g.pattern = '&lt;bg color="#ff6565"/&gt;$load%' end</code><br/>
-- <code>gadget:add_event(t, a)</code>
--
-- <br/><br/>
-- This module provides the different Trigger prototypes.
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module('flaw.event')


--- The simple trigger prototype.
--
-- <br/><br/>
-- The trigger is the activation object of an event. It is tested by a
-- gadget provider each time its data are refreshed. The test can use
-- the furnished provider data and any other information the user
-- provided.
-- <br/><br/>
-- The simple trigger starts the event it belongs to each time the
-- condition is successfully checked.
--
-- <br/><br/>
-- @class table
-- @name Trigger
-- @field condition the boolean computing routine, normally provided
--        by the user, which decides if the event should be started.
Trigger = { condition = function() return true end }

-- The simple trigger constructor.
function Trigger:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

-- Event trigger using the raw condition.
function Trigger:test(data)
   return self.condition(data)
end

--- The latch trigger prototype.
-- <br/><br/>
-- The latch trigger starts the event it belongs to only when the
-- condition becomes true. That is, while the condition remains true,
-- the event is started exactly once. It will be started again only if
-- the condition becomes false again and then true.
-- <br/><br/>
-- @class table
-- @name LatchTrigger
-- @field condition the boolean computing routine, normally provided
--        by the user, which decides if the event should be started.
-- @field status the trigger memory.
LatchTrigger = Trigger:new{ status = false }

-- Event trigger using a bistable mechanism around the raw condition.
function LatchTrigger:test(data)
   local old_status = self.status
   self.status = self.condition(data)
   return not old_status and self.status
end

--- The edge trigger prototype.
-- <br/><br/>
-- The edge trigger starts the event it belongs to only when the
-- condition result changes. That is, the event is started each time
-- the condition becomes true or becomes false.
-- <br/><br/>
-- @class table
-- @name EdgeTrigger
-- @field condition the boolean computing routine, normally provided
--        by the user, which decides if the event should be started.
-- @field status the trigger memory.
EdgeTrigger = Trigger:new{ status = false }

-- Event trigger using edge detection of the raw condition results.
function EdgeTrigger:test(data)
   local old_status = self.status
   self.status = self.condition(data)
   return old_status and not self.status or not old_status and self.status
end
