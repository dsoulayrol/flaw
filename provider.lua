-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;


-- Grab environment.
local os = os
local setmetatable = setmetatable
local table = table

local awful = {
   hooks = require('awful.hooks')
}

local flaw = {
   helper = require('flaw.helper'),
}


-- Providers handling for Flaw.
--
-- Common behaviours for Flaw providers.
module('flaw.provider')


-- The Provider prototype provides common behaviour and properties for
-- widgets in a Flaw configuration.
Provider = { type = 'unknown', id = nil, interval = 5, timeout = 0 }

-- Provider constructor.
-- @param o a table with default values.
function Provider:new(o)
   o = o or {}
   o.data = {}
   o.triggers = { activated = {}, all = {} }
   setmetatable(o, self)
   self.__index = self
   return o
end

-- Update provider interval.
function Provider:set_interval(interval)
   if interval ~= nil and interval < self.interval then
      self.interval = interval
      return true
   end
   return false
end

-- Update provider interval.
function Provider:add_trigger(t)
   if t ~= nil then
      table.insert(self.triggers.all, t)
   end
end

-- Check whether cached data are no more valid.
function Provider:is_dirty()
   return self.timeout < os.time()
end

-- Refresh the provider status if necessary.
function Provider:refresh()
   if self:is_dirty() then
      self:do_refresh()
      self.triggers.activated = {}
      for i, t in ipairs(self.triggers.all) do
         if t:test(self.provider.data) then
            table.insert(self.triggers.activated, t)
         end
      end
      self.timeout = os.time() + self.interval
   end
   return self.triggers.activated
end

-- Callback for provider refresh. This function is called if
-- the provider needs to refresh its data.
function Provider:do_refresh()
end


-- Global providers storage management.
local _providers_cache = {}

-- Add a provider to the cache.
-- @param p the provider to store.
function add(p)
   if p == nil or p.id == nil then
      flaw.helper.debug.error('flaw.provider.provider_add: invalid provider.')
   else
      if _providers_cache[p.type] == nil then
         _providers_cache[p.type] = {}
      end
      _providers_cache[p.type][p.id] = p
   end
end

-- Retrieve a provider from the cache using a type and an identifier.
-- @param type the type of the provider to retrieve.
-- @param id the identifier of the provider to retrieve.
function get(type, id)
   if type == nil or id == nil then
      flaw.helper.debug.error('flaw.provider.provider_get: invalid information.')
   else
      return _providers_cache[type] ~= nil
         and _providers_cache[type][id] or nil
   end
end
