-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

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


-- Cpu module implementation
--
-- This module contains a provider for cpu information and two
-- gadgets: a text gadget and a graph gadget.
module('flaw.cpu')

-- The cpu provider.
CPUProvider = flaw.provider.Provider:new{ type = _NAME, data = {} }

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

-- A factory for cpu providers.
-- Only one provider is built for a CPU ID. Created providers are stored
-- in the provider cache. See provider.add ant provider.get.
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
CPUTextGadget = flaw.gadget.TextGadget:new{ type = _NAME .. '.TextGadget' }

-- An graph gadget for cpu load display.
CPUGraphGadget = flaw.gadget.GraphGadget:new{ type = _NAME .. '.GraphGadget' }

-- An icon gadget for cpu status display.
CPUIconGadget = flaw.gadget.IconGadget:new{ type = _NAME .. '.IconGadget' }

function CPUIconGadget:update()
   if self.provider ~= nil then
      self.provider:refresh()
      if self.provider.data.status ~= self.status then
         self.status = self.provider.data.status
         self.widget.icon = self.images[self.status]
      end
   end
end

-- Text gadget factory.
function text_gadget_new(id, delay, pattern, alignment)
   slot = slot or 'cpu'
   delay = delay or 2
   pattern = pattern or '$load_user/$load_sum'
   alignment = alignment or 'right'

   local gadget = CPUTextGadget:new{
      id = id,
      widget = capi.widget{ type = 'textbox', align = alignment },
      pattern = pattern,
      provider = CPUProviderFactory(id)
   }
   gadget.widget.name = id
   gadget.provider.set_interval(delay)

   gadget:register(delay)
   flaw.gadget.add(gadget)

   return gadget
end

-- Graph gadget factory.
function graph_gadget_new(id, delay, values, alignment)
   slot = slot or 'cpu'
   delay = delay or 2
   values = values or { 'load_sum' }
   alignment = alignment or 'right'

   local gadget = CPUGraphGadget:new{
      id = slot,
      widget = capi.widget{ type = 'graph', name = id, align = alignment },
      values = values,
      provider = CPUProviderFactory(slot)
   }

-- TODO: customization
--   gadget.widget.width = "35"
--   gadget.widget.height = "0.8"
--   gadget.widget.grow = "right"
--   gadget.widget.bg = beautiful.bg_focus
--   gadget.widget.border_color =

   gadget.widget.max_value = "100"
   -- gadget.widget:plot_properties_set('cpu', {
   --                                      fg = beautiful.fg_normal,
   --                                      fg_end = beautiful.fg_urgent
   --                                   })

   gadget.provider.set_interval(delay)

   gadget:register(delay)
   flaw.gadget.add(gadget)

   return gadget
end
