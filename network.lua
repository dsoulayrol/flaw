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
local math = math
local tonumber = tonumber
local os = os
local string = string

local beautiful = require('beautiful')
local naughty = require('naughty')

local flaw = {
   helper = require('flaw.helper'),
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider')
}


--- Network activity gadgets and provider.
--
-- <p>This module contains a provider for network status and activity and two
-- gadgets: a text gadget and a graph gadget.</p>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module('flaw.network')


-- Bandwidth in bytes.
-- TODO: should become a parameter for the provider.
BANDWIDTH = 120000

--- The network provider prototype.
NetworkProvider = flaw.provider.CyclicProvider:new{ type = _NAME }

--- Callback for provider refresh.
function NetworkProvider:do_refresh()
   local file = io.open('/proc/net/dev')
   local sep
   local adapter
   local line = ''
   local input, output

   while line ~= nil do
      line = file:read()

      if line ~= nil then
         -- Skip the adapter prefix.
         sep = string.find (line, ':')
         if sep ~= nil then
            adapter = flaw.helper.strings.lstrip(string.sub(line, 0, sep - 1))
            if adapter ~= nil then
               if self.data[adapter] == nil then
                  self.data[adapter] = {
                     all_net_in = 0, all_net_out = 0, net_in = 0, net_out = 0 }
               end
               -- First decimal number are total bytes
               local split_line = flaw.helper.strings.split(
                  string.sub(line, sep + 1))
               local interval = os.time() - self.timestamp

               input = tonumber(split_line[1])
               output = tonumber(split_line[9])

               self.data[adapter].net_in =
                  (input - self.data[adapter].all_net_in) / interval
               self.data[adapter].net_out =
                  (output - self.data[adapter].all_net_out) / interval

               self.data[adapter].percents_in =
                  (self.data[adapter].net_in / BANDWIDTH) * 100
               self.data[adapter].percents_out =
                  (self.data[adapter].net_out / BANDWIDTH) * 100

               self.data[adapter].all_net_in = input
               self.data[adapter].all_net_out = output
            end
         end
      end
   end
   io.close(file);
end

--- A factory for network providers.
--
-- <p>Only one provider is built for all network adapters. The provider is
-- stored in the provider cache.</p>
--
-- @return a brand new network provider, or the existing one if any.
function provider_factory()
   local p = flaw.provider.get(_NAME, '')
   -- Create the provider if necessary.
   if p == nil then
      p = NetworkProvider:new{ id = '', data = {} }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget for network status display.
flaw.gadget.register.text(_M, { delay = 1, pattern = 'in:$net_in out:$net_out' })

-- A graph gadget for network load display.
flaw.gadget.register.graph(_M, { delay = 1, values = { 'percents_in' } })

-- An icon gadget for network status display.
flaw.gadget.register.icon(_M)
