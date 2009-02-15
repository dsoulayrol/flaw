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

local flaw = {
   helper = require('flaw.helper'),
}


--- Providers core mechanisms.
--
-- <p><b>flaw</b> tries to minimise system access and data refresh.
-- Since all information do not have the same expiration rate, all
-- gadgets refresh themselves independently. And since some gadgets
-- can share information, all data is provided by provider objects
-- which can be shared among gadgets. Providers maintain status data
-- from the system and update themselves only when necessary (ie. when
-- the gadget with the shortest refresh rate demands it).</p>
--
-- <p>Providers are normally handled automatically when a gadget is
-- created. You only have to take care of them when you are writing
-- your own gadget, or if you want to create a new provider, or extend
-- an existing one.</p>
--
-- <p><b>flaw</b> provides many providers for common system
-- information. Actually, there is nearly one provider per information
-- type. The existing providers are stored in the module of the widget
-- type they serve.</p>
--
-- <p>A provider is identified by its type and an identifier, which
-- must remain unique for one type. The provider type usually
-- represents the module of this provider and can be composed of any
-- character. Thus, it is common to create a new provider prototype
-- this way:</p>
--
-- <div class='example'>
-- flaw.provider.Provider:new{ type = _NAME }
-- </div>
--
-- <p>All created providers are kept in a <a
-- href='#_providers_cache'>global store</a> from which they can be
-- retrieved anytime. Note that this store has normally no use for the
-- user, but allows gadgets to share providers.</p>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module('flaw.provider')


--- Global providers store.
--
-- <p>This table stores all the registered provider
-- instances. Providers are sorted by their type first, and then by
-- their ID. The store is private to the <code>provider</code>
-- module. It can be accessed using its <a
-- href='#get'><code>get</code></a>, and <a
-- href='#add'><code>add</code></a> functions.</p>
--
-- @class table
-- @name _providers_cache
local _providers_cache = {}

--- Store a provider instance.
--
-- <p>This function stores the given provider in the global providers
-- store. It fails if the instance is invalid, that is if it is nil or
-- if its type is nil.</p>
--
-- <p>You normally do not have to call this function since it is
-- silently invoked each time a gadget instantiates its provider.</p>
--
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
-- <p>This function returns the provider matching the given
-- information. It immediately fails if the given type or identifier
-- is nil. It also fails if no instance in the store matches the given
-- parameters.</p>
--
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
-- <p>This is the root prototype of all providers. It provides common
-- methods for refresh handling. It also defines the following
-- mandatory properties.</p>
--
-- <ul>
-- <li><code>interval</code><br/>
-- This is the provider refresh rate. Its default value is 10 seconds
-- but it is normally updated each time a gadget starts to use the
-- provider.</li>
-- <li><code>timestamp</code><br/>
-- This is the time stamp of the current data set. The provider only
-- updates itself if asked to do so after the <code>interval</code>
-- value from this time stamp. The timestamp value is initialised to 0
-- and is reset each time the provider updates itself.</li>
-- </ul>
--
-- @class table
-- @name Provider
Provider = { type = 'unknown', interval = 10, timestamp = 0 }

--- Provider constructor.
--
-- <p>Remember that providers are normally handled automatically when
-- a gadget is created. This constructor is only used internally, or
-- to create new gadget prototypes.</p>
--
-- @param  o a table with default values.
-- @return The brand new provider.
function Provider:new(o)
   o = o or {}
   o.data = o.data or {}
   o.subscribers = o.subscribers or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

--- Subscribe a gadget to this provider.
--
-- <p>This is the method a gadget automatically uses, when created by the
-- gadget factory, to register itself to its provider. By registering
-- itself, the gadget can ask for a new poll interval to the
-- provider. The provider will store the new interval if it is
-- inferior to its current poll delay.</p>
--
-- <p>This method immediately fails if the given gadget is nil. On
-- success, the gadget is stored in the provider internal subscribers
-- list.</p>
--
-- @param  g the gadget subscriber.
-- @param  delay the new poll interval asked by the a table with
--         default values.
-- @return True if the subscriber was correctly stored, False otherwise.
function Provider:subscribe(g, delay)
   if g == nil then
      flaw.helper.debug.error('flaw.provider.Provider:subscribe: invalid gadget')
   else
      self.subscribers[g] = 0
      if delay ~= nil and delay < self.interval then
         self.interval = delay
      end
      return true
   end
   return false
end

--- Check whether cached data are still valid.
--
-- @return True is the provider should refresh its data set, False otherwise.
function Provider:is_dirty()
   return self.timestamp <= os.time() - self.interval
end

--- Refresh the provider status if necessary.
--
-- <p>This is the method invoked by the provider subscribers when they
-- want to update themselves. The refresh is achieved only if <a
-- href='#Provider:is_dirty'><code>Provider:is_dirty</code></a>
-- returns true.</p>
--
-- <p>This method actually only checks if refresh is necessary, and
-- eventually invokes another method do to it. The actual refresh
-- process is dedicated to the <code>do_refresh</code> method, which
-- is called with no argument. This definition depends on the provider
-- role, and should be defined in all derived prototypes.</p>
--
-- @param  g the gadget which is asking for the provider to refresh.
-- @return True is the provider did refresh its data set since the
--         given gadget last asked for the refresh.
function Provider:refresh(g)
   if self:is_dirty() then
      if self.do_refresh then self:do_refresh() end
      self.timestamp = os.time()
      if g ~= nil and self.subscribers[g] ~= nil then
         self.subscribers[g] = self.timestamp
      return true
      end
   else
      if g ~= nil and self.subscribers[g] ~= nil then
         return self.subscribers[g] < self.timestamp
      end
   end
   return false
end
