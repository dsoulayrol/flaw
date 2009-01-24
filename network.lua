-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

-- Grab environment.
local io = io
local math = math
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


-- Network module implementation
--
-- This module contains a provider for network information and two
-- gadgets: a text gadget and an icon gadget.
module('flaw.network')

-- The network provider.
NetworkProvider = flaw.provider.Provider:new{ type = _NAME, data = {} }

-- Callback for provider refresh.
-- See Provider:do_refresh.
function NetworkProvider:do_refresh()
   local file = io.open('/proc/net/dev')
   local sep
   local adapter
   local line = ''
   local tot_eth_in, tot_eth_out

   while line ~= nil do
      line = file:read()

      if line ~= nil then
         -- Skip the adapter prefix.
         sep = string.find (line, ':')
         if sep ~= nil then
            adapter = flaw.helper.strings.lstrip(string.sub(line, 0, sep - 1))
            if adapter ~= nil then
               if self.data[adapter] == nil then
                  flaw.helper.debug.display('create ' .. adapter)
                  self.data[adapter] = {}
                  self.data[adapter].net_in = 0
                  self.data[adapter].net_out = 0
               end

               -- flaw.helper.debug.display(adapter)

               -- First decimal number are total bytes
               tot_eth_in = string.match(line, '%s*%d+', sep)
               tot_eth_out = string.gsub(
                  line, '^.*:%s*%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+%d+%s+(%d+).*$', '%1')
               eth_in = (tot_eth_in - self.data[adapter].net_in) / 1024
               eth_out = (tot_eth_out - self.data[adapter].net_out) / 1024

               self.data[adapter].net_in = string.format("%5.1f", eth_in)
               self.data[adapter].net_out = string.format("%4.1f", eth_out)
            end
         end
      end
   end
   io.close(file);
end

-- A factory for network providers.
-- Only one provider is built for all netword adapters. The provider is
-- stored in the provider cache. See provider.add ant provider.get.
function NetworkProviderFactory()
   local p = flaw.provider.get(_NAME, '')
   -- Create the provider if necessary.
   if p == nil then
      p = NetworkProvider:new{ id = '' }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget for network status display.
NetworkTextGadget = flaw.gadget.TextGadget:new{ type = _NAME .. '.TextGadget' }

-- Text gadget factory.
function text_gadget_new(adapter, delay, pattern, alignment)
   adapter = adapter or 'eth0'
   delay = delay or 5
   pattern = pattern or 'in:$net_in out:$net_out'
   alignment = alignment or 'right'

   local gadget = NetworkTextGadget:new{
      id = adapter,
      widget = capi.widget{ type = "textbox" },
      pattern = pattern,
      provider = NetworkProviderFactory()
   }
   gadget.widget.name = adapter
   gadget.widget.alignment = alignment
   gadget.provider.set_interval(delay)

   gadget:register(delay)
   flaw.gadget.add(gadget)

   return gadget
end
