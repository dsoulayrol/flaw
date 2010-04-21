-- flaw, a Lua OO management framework for Awesome WM widgets.
-- Copyright (C) 2010 David Soulayrol <david.soulayrol AT gmail DOT net>

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
local capi = {
   client = client,
}

local awful = {
   util = require("awful.util"),
}

local flaw = {
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider'),
   helper = require('flaw.helper'),
}

--- Clients title display.
--
-- <p>This module contains a simple text gadget which displays the
-- title of the active client, and its provider.</p>
--
-- <div class='example'>
-- g = flaw.gadget.TitleTextbox()<br/>
-- </div>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2010, David Soulayrol
module('flaw.title')

--- The client events provider prototype.
--
-- @class table
-- @name ClientProvider
ClientProvider = flaw.provider.Provider:new{ type = _NAME }

function ClientProvider:update(c)
   if c and c.name and capi.client.focus == c then
      self.data.title = awful.util.escape(c.name)
      self:refresh_gadgets()
   end
end

function ClientProvider:reset(c)
   if c then
      self.data.title = ''
      self:refresh_gadgets()
   end
end

--- A factory for client providers.
--
-- @return a brand new client provider.
function ClientProviderFactory()
   local p = flaw.provider.get(_NAME, '')
   -- Create the provider if necessary.
   if p == nil then
      p = ClientProvider:new{ id = '', data = { title = '' } }
      flaw.provider.add(p)

      -- Init signals once for the provider.
      capi.client.add_signal(
         'manage',
         function (c, startup)
            c:add_signal('property::name',
                         function(c)
                            p:update(c)
                         end)
         end)
      capi.client.add_signal('focus', function(c) p:update(c) end)
      capi.client.add_signal('unfocus', function(c) p:reset(c) end)
   end
   return p
end


-- A Text gadget prototype for clients title display.
flaw.gadget.register(
   'TitleTextbox', flaw.gadget.TextGadget:new{}, ClientProviderFactory,
   { pattern = '$title' })
