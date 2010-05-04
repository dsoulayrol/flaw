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

local beautiful = require('beautiful')
local naughty = require('naughty')

local flaw = {
   helper = require('flaw.helper'),
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider')
}


-- Cpu module implementation
--
-- This module contains a provider for cpu information and two
-- gadgets: a text gadget and a graph gadget.
module('flaw.cpu')

-- The cpu provider.
CPUProvider = flaw.provider.CyclicProvider:new{ type = _NAME, data = {} }

-- Callback for provider refresh.
-- See Provider:do_refresh.
function CPUProvider:do_refresh()
   local file = io.open('/proc/stat')
   local line = ''

   local id, user, nice, system, idle, diff

   while line ~= nil do
      line = file:read()

      if line ~=nil then
         id, user, nice, system, idle = string.match(
            line, '(%w+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)')

         if id ~=nil and string.find(id, 'cpu') ~= nil then

            if self.data[id] == nil then
               self.data[id] = {
                  raw_user = 0, raw_nice = 0, raw_idle = 0, raw_sum = 0,
                  load_user = 0, load_nice = 0, load_sum = 0 }
            end

            local cpu_sum = user + nice + system + idle
            diff = cpu_sum - self.data[id].raw_sum

            -- The diff should always be positive. If it is not the case,
            -- the load is too heavy for the system to refresh data. In
            -- this case, keep a 100 USER_HZ default value.
            self.data[id].load_user = 100
            self.data[id].load_nice = 100
            self.data[id].load_sum = 100
            if diff > 0 then
               self.data[id].load_user =
                  100 * (user - self.data[id].raw_user) / diff
               self.data[id].load_nice =
                  100 * (nice - self.data[id].raw_nice) / diff
               self.data[id].load_sum =
                  100 - 100 * (idle - self.data[id].raw_idle) / diff
            end

            self.data[id].raw_sum = cpu_sum
            self.data[id].raw_user = user
            self.data[id].raw_nice = nice
            self.data[id].raw_idle = idle
         end
      end
   end
   io.close(file);
end

-- A factory for cpu providers. Only one provider is built for a CPU
-- ID. Created providers are stored in the provider cache. See
-- provider.add ant provider.get.
function CPUProviderFactory()
   local p = flaw.provider.get(_NAME, '')
   -- Create the provider if necessary.
   if p == nil then
      p = CPUProvider:new{ id = '' }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget for cpu status display.
flaw.gadget.register(
   'CPUTextbox', flaw.gadget.TextGadget:new{}, CPUProviderFactory,
   { delay = 1, pattern = '$load_user/$load_sum' })

-- A graph gadget for cpu load display.
flaw.gadget.register(
   'CPUGraph', flaw.gadget.GraphGadget:new{}, CPUProviderFactory,
   { delay = 1, values = { 'load_sum' } })

-- An icon gadget for cpu status display.
flaw.gadget.register(
   'CPUIcon', flaw.gadget.IconGadget:new{}, CPUProviderFactory)
