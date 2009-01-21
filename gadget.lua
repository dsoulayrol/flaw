-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

-- Grab environment.
local setmetatable = setmetatable
local tostring = tostring -- For Debug only.

local capi = {
   widget = widget,
}

local awful = {
   hooks = require('awful.hooks')
}

local flaw = {
   helper = require('flaw.helper'),
}


-- Gadgets handling for Flaw.
--
-- Common behaviours for Flaw gadgets and high level gadget
-- definitions.
module('flaw.gadget')


-- Global gadgets storage management.
local _gadgets_cache = {}

-- Add a gadget to the cache.
-- @param g the gadget to store.
function add(g)
   if g == nil or g.id == nil then
      error('flaw.gadget.gadget_add: invalid gadget.')
   end
   if _gadgets_cache[g.type] == nil then
      _gadgets_cache[g.type] = {}
   end
   _gadgets_cache[g.type][g.id] = g
end

-- Retrieve a gadget from the cache using a type and an identifier.
-- @param type the type of the gadget to retrieve.
-- @param id the identifier of the gadget to retrieve.
function get(type, id)
   if type == nil or id == nil then
      error('flaw.gadget.gadget_get: invalid information.')
   else
      return _gadgets_cache[type] ~= nil
         and _gadgets_cache[type][id] or nil
   end
end


-- The Gadget prototype provides common behaviour and properties for
-- widgets in a Flaw configuration.
Gadget = { type = 'unknown', id = nil, widget = nil, provider = nil }

-- Gadget constructor.
-- @param o a table with default values. Most useful keys are type,
--        id and widget.
function Gadget:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

-- Hook the gadget to tick events.
-- @param delay the delay between gadget updates in seconds
--        (default value is 10).
function Gadget:register(delay)
   delay = delay or 10  
   awful.hooks.timer.register(delay, 
                              function() self:update() end,
                              true)
end

-- Callback for gadget refresh. This function is called by awful if
-- the gadget has been registered to tick events.
function Gadget:update()
end


-- The TextGadget prototype provides a pattern mechanism.
TextGadget = Gadget:new{ type = 'text', widget = nil, pattern = nil }

-- Callback for gadget refresh. See Gadget:update.
function TextGadget:update()
   if self.provider ~= nil then
      self.provider:refresh()
      self.widget.text =
         flaw.helper.strings.format(self.pattern, self.provider.data)
   end
end


-- The IconGadget prototype provides a simple icon view.
IconGadget = Gadget:new{ 
   type = 'icon',
   widget = capi.widget{ type = 'imagebox' },
   images = nil
}
