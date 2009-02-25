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
local string = string

local capi = {
   widget = widget,
   image = image,
}

local beautiful = require('beautiful')
local naughty = require('naughty')

local flaw = {
   helper = require('flaw.helper'),
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider')
}


--- Memory information gadgets and provider.
--
-- <p>This module contains a provider for memory status and two
-- gadgets: a text gadget and a graph gadget.</p>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module('flaw.memory')


--- The memory provider prototype.
--
-- <p>
-- The memory provider type is set to memory._NAME. Its status data
-- are read from <code>/proc/meminfo</code>.</p>
--
-- <p>
-- The provider data provides the quantity of memory occupied in
-- <code>data.ratio</code>. <code>data.proc</code> contains the values
-- read in the source file. Remarquable values are:</p>
--
-- <ul>
-- <li><code>meminfo_memtotal</code><br/>
-- The memory available on the system.</li>
-- <li><code>meminfo_cached</code><br/>
-- The memory affected to cached data.</li>
-- <li><code>meminfo_buffers</code><br/>
-- The memory affected to application buffers data.</li>
-- <li><code>meminfo_memfree</code><br/>
-- The free memory.</li>
-- </ul>
--
-- @class table
-- @name MemoryProvider
MemoryProvider = flaw.provider.Provider:new{ type = _NAME, data = {} }

--- Callback for provider refresh.
function MemoryProvider:do_refresh()
   local r = false
   local p = self.data.proc

   r = flaw.helper.file.load_state_file('/proc', 'meminfo', p)

   self.data.ratio = 0
   if r then
      -- Adapt values.
      local total = p.meminfo_memtotal:match('(%d+).*') or 0
      local free = p.meminfo_memfree:match('(%d+).*') or 0
      local buffers = p.meminfo_buffers:match('(%d+).*') or 0
      local cached = p.meminfo_cached:match('(%d+).*') or 0

      if total ~= 0 then
         self.data.ratio = flaw.helper.round(
            100 * (total - free - buffers - cached) / total, 2)
      end
   end
end

--- A factory for memory providers.
--
-- <p>Only one provider is built. Created provider is stored in the
-- global provider cache.</p>
--
-- @return a brand new memory provider, or the existing one if any.
function MemoryProviderFactory()
   local p = flaw.provider.get(_NAME, '')
   -- Create the provider if necessary.
   if p == nil then
      p = MemoryProvider:new{
         id = '', data = { ratio = 0, proc = {} } }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget for memory status display.
flaw.gadget.register(
   flaw.gadget.TextGadget:new{ type = _NAME .. '.textbox' },
   MemoryProviderFactory,
   { pattern = '$ratio%' }
)
