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
local ipairs = ipairs
local os = os
local setmetatable = setmetatable
local table = table

local flaw = {
   helper = require('flaw.helper'),
}


--- Providers handling for Flaw.
--
-- <br/><br/>
-- <b>flaw</b> tries to minimise system access and data refresh.
-- Since all information do not have the same expiration rate, all
-- gadgets refresh themselves independently. And since some gadgets
-- can share information, all data is provided by provider objects
-- which can be shared among gadgets. Providers maintain status data
-- from the system and update themselves only when necessary (ie. when
-- the gadget with the shortest refresh rate demands it).
--
-- <br/><br/>
-- Providers are normally handled automatically when a gadget is
-- created. You only have to take care of them when you are writing
-- your own gadget, or if you want to create a new provider, or extend
-- an existing one.
--
-- <br/><br/>
-- <b>flaw</b> provides many providers for common system
-- information. Actually, there is nearly one provider per information
-- type. The existing providers are stored in the module of the
-- widget type they serve.
--
-- <br/><br/>
-- A provider is identified by its type and an identifier, which must
-- remain unique for one type. The provider type usually represents the
-- module of this provider and can be composed of any character. Thus,
-- it is common to create a new provider prototype this way:
--
-- <br/><code>&nbsp;&nbsp;&nbsp;
-- flaw.provider.Provider:new{ type = _NAME }</code>
--
-- <br/><br/>
-- All created providers are kept in a <a
-- href='#_providers_cache'>global store</a> from which they can be
-- retrieved anytime. Note that this store has normally no use for the
-- user, but allows gadgets to share providers.
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module('flaw.provider')


--- Global providers store.
--
-- <br/><br/>
-- This table stores all the registered provider instances. Providers
-- are sorted by their type first, and then by their ID. The store is
-- private to the <code>provider</code> module. It can be accessed
-- using its <a href='#get'><code>get</code></a>, and <a
-- href='#add'><code>add</code></a> functions.
--
-- @class table
-- @name _providers_cache
local _providers_cache = {}

--- Store a provider instance.
--
-- <br/><br/>
-- This function stores the given provider in the global providers
-- store. It fails if the instance is invalid, that is if it is nil
-- or if its type is nil.
--
-- <br/><br/>
-- You normally do not have to call this function since it is silently
-- invoked each time a gadget instantiates its provider.
--
-- <br/><br/>
-- @param  p the provider prototype to store.
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

--- Retrieve a provider instance.
--
-- <br/><br/>
-- This function returns the provider matching the given information. It
-- immediately fails if the given type or identifier is nil. It also
-- fails if no instance in the store matches the given parameters.
--
-- <br/><br/>
-- @param  type the type of the provider to retrieve.
-- @param  id the uniquer identifier of the provider to retrieve.
-- @return The matching provider instance, or nil if information was
--         incomplete or if there is no such provider.
function get(type, id)
   if type == nil or id == nil then
      flaw.helper.debug.error('flaw.provider.provider_get: invalid information.')
   else
      return _providers_cache[type] ~= nil
         and _providers_cache[type][id] or nil
   end
end


--- The Provider prototype.
--
-- <br/><br/>
-- This is the root prototype of all providers. It provides common
-- methods for triggers and refresh handling. It also defines the
-- following mandatory properties.
-- <ul>
-- <li><code>interval</code><br/>
-- This is the provider refresh rate. Its default value is 10 seconds
-- but it is normally updated each time a gadget starts to use the
-- provider.</li>
-- <li><code>timeout</code><br/>
-- This is the time stamp for the next refresh. The provider only
-- updates itself if asked to do so after this time stamp. Its value
-- is initialised to 0 and is reset each time the provider updates
-- itself.</li>
-- </ul>
--
-- @class table
-- @name Provider
Provider = { type = 'unknown', interval = 10, timeout = 0 }

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
