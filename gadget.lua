-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

-- Grab environment.
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local string = string
local tonumber = tonumber
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

-- Create a new entry in the gadgets cache.
function register(c, pc, p, o)
   if c == nil or c.type == nil then
      flaw.helper.debug.error('flaw.gadget.record: invalid class.')
      return
   end

   -- Store default important values.
   p = p or {}
   if p.delay == nil then p.delay = 10 end

   o = o or {}
   if o.alignment == nil then o.alignment = 'right' end

   _gadgets_cache[c.type] = {
      prototype = c,
      provider = pc,
      instances = {},
      defaults = { gadget = p, widget = o }
   }
end

-- Add a gadget to the cache.
-- @param g the gadget to store.
-- @return the gadget stored, or nil.
function add(g)
   if g == nil or g.type == nil or g.id == nil then
      flaw.helper.debug.error('flaw.gadget.add: invalid gadget.')
   else
      if _gadgets_cache[g.type] == nil then
         flaw.helper.debug.error('flaw.gadget.add: unknown gadget class: ' .. g.type)
      end
      _gadgets_cache[g.type][g.id] = g
      return g
   end
end

-- Retrieve a gadget from the cache using a type and an identifier.
-- @param type the type of the gadget to retrieve.
-- @param id the identifier of the gadget to retrieve.
function get(type, id)
   if type == nil or id == nil then
      flaw.helper.debug.error('flaw.gadget.get: invalid information.')
   else
      return _gadgets_cache[type] ~= nil
         and _gadgets_cache[type].instances[id] or nil
   end
end

-- Create a new gadget.
function new(type, id, p, o)
   if type == nil or id == nil then
      flaw.helper.debug.error('flaw.gadget.new: invalid information.')
      return
   end

   local entry = _gadgets_cache[type]
   if entry == nil then
      -- print('flaw.gadget.new: unknown gadget class: ' .. type)
      return nil
   end

   -- Load default parameters.
   p = p or {}
   o = o or {}
   for k in pairs(entry.defaults.gadget) do
      p[k] = p[k] or entry.defaults.gadget[k]
   end
   for k in pairs(entry.defaults.widget) do
      o[k] = o[k] or entry.defaults.widget[k]
   end

   -- Create the widget.
   local proto = entry.prototype
   local g = proto:new{
      id = id,
      provider = _gadgets_cache[type].provider(id),
      widget = capi.widget{
         type = proto:get_widget_type(),
         name = id,
         align = o.alignment }
   }

   -- Configure the gadget.
   for k in pairs(p) do g[k] = p[k] end
   for k in pairs(o) do g.widget[k] = o[k] end

   -- Start monitoring.
   g:register(p.delay)

   return add(g)
end

-- The Gadget prototype provides common behaviour and properties for
-- widgets in a Flaw configuration.
--
-- The gadget type MUST be composed of two parts. The first represents
-- the module this gadget is part of and can be composed of any
-- character. The second, separated from the first one by a dot, is
-- the kind of widget used internally (ie. graph or textbox). It MUST
-- match exactly a widget type as defined in Awful API.
Gadget = { type = 'unknown.unknown', id = nil, widget = nil, provider = nil }

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

   -- Update provider delay.
   if self.provider ~= nil then
      self.provider.set_interval(delay)
   end

   awful.hooks.timer.register(delay, function() self:update() end, true)
end

-- Callback for gadget refresh. This function is called by awful if
-- the gadget has been registered to tick events.
function Gadget:update()
end

-- Retrieve the type of the widget used by this gadget.
function Gadget:get_widget_type()
   return string.match(self.type, '.*%.(%a+)')
end


-- The TextGadget prototype provides a pattern mechanism.
TextGadget = Gadget:new{ type = 'unknown.textbox', widget = nil, pattern = nil }

-- Callback for gadget refresh. See Gadget:update.
--
-- This implementation support two data models. First, it can apply
-- the pattern directly on the provider data. But if the gadget ID is
-- a key of the provider data, then the update is achieved by applying
-- the pattern to the content of this entry.
function TextGadget:update()
   if self.provider ~= nil and self.provider.data ~= nil then
      self.provider:refresh()
      local data_set = self.provider.data[self.id] or self.provider.data
      self.widget.text = flaw.helper.strings.format(self.pattern, data_set)
   end
end

-- The GraphGadget prototype provides a list of values to plot.
GraphGadget = Gadget:new{ type = 'unknown.graph', widget = nil, values = {} }

-- Callback for gadget refresh. See Gadget:update.
--
-- This implementation support two data models. First, it can apply
-- the pattern directly on the provider data. But if the gadget ID is
-- a key of the provider data, then the update is achieved by applying
-- the pattern to the content of this entry.
function GraphGadget:update()
   if self.provider ~= nil and self.provider.data ~= nil then
      self.provider:refresh()
      local data_set = self.provider.data[self.id] or self.provider.data
      for i, v in ipairs(self.values) do
         self.widget:plot_data_add(v, tonumber(data_set[v]))
      end
   end
end


-- The IconGadget prototype provides a simple icon view.
IconGadget = Gadget:new{ type = 'unknown.imagebox', images = {} }
