-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

-- Grab environment.
local io = io
local math = math
local tonumber = tonumber

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


-- Battery module implementation
--
-- This module contains a provider for battery information and two
-- gadgets: a text gadget and an icon gadget.
module('flaw.battery')

-- Battery statuses.
local STATUS_UNKNOWN = '='
local STATUS_PLUGGED = '(A/C)'
local STATUS_CHARGING = '^'
local STATUS_DISCHARGING = 'v'

-- The battery provider.
BatteryProvider = flaw.provider.Provider:new{ type = _NAME }
BatteryProvider.data.load = '0'
BatteryProvider.data.status = ''

-- Callback for provider refresh.
-- See Provider:do_refresh.
function BatteryProvider:do_refresh()
   local fcur = io.open("/sys/class/power_supply/" .. self.id .. "/charge_now")
   local fcap = io.open("/sys/class/power_supply/" .. self.id .. "/charge_full")
   local f_status = io.open("/sys/class/power_supply/" .. self.id .. "/status")
   local load = math.floor(fcur:read() * 100 / fcap:read())
   local raw_status = f_status:read()
   fcur:close()
   fcap:close()
   f_status:close()

   local status = STATUS_PLUGGED

   if raw_status:match("Charging") then
      status = STATUS_CHARGING

   elseif raw_status:match("Discharging") then
      status = STATUS_DISCHARGING

      if tonumber(load) > 25 and tonumber(load) < 75 then
         load = flaw.helper.format.set_fg("#e6d51d", load)
      elseif tonumber(load) < 25 then
         if tonumber(load) < 10 then
            naughty.notify{
               title = "Battery Warning",
               text = "Battery low!" .. load .. "%" .. "left!",
               timeout = 5,
               position = "top_right",
               fg = beautiful.fg_focus,
               bg = beautiful.bg_focus}
         end
         load = flaw.helper.format.set_fg("#ff6565", load)
      end
   end
   self.data.load = load
   self.data.status = status
end

-- A factory for battery providers.
-- Only one provider is built for a slot. Created providers are stored
-- in the provider cache. See provider.add ant provider.get.
function BatteryProviderFactory(slot)
   local p = flaw.provider.get(_NAME, slot)
   -- Create the provider if necessary.
   if p == nil then
      p = BatteryProvider:new{ id = slot }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget for battery status display.
BatteryTextGadget = flaw.gadget.TextGadget:new{ type = _NAME .. '.TextGadget' }

-- An icon gadget for battery status display.
BatteryIconGadget = flaw.gadget.IconGadget:new{ type = _NAME .. '.IconGadget' }

function BatteryIconGadget:update()
   if self.provider ~= nil then
      self.provider:refresh()
      if self.provider.data.status ~= self.status then
         self.status = self.provider.data.status
         self.widget.icon = self.images[self.status]
      end
   end
end

-- Text gadget factory.
function text_gadget_new(slot, delay, pattern, alignment)
   slot = slot or 'BAT0'
   delay = delay or 10
   pattern = pattern or '$load% $status'
   alignment = alignment or 'right'

   local battery = BatteryTextGadget:new{
      id = slot,
      pattern = pattern,
      provider = BatteryProviderFactory(slot)
   }
   battery.widget.name = slot
   battery.widget.alignement = alignment
   battery.provider.set_interval(delay)

   battery:register(delay)
   flaw.gadget.add(battery)

   return battery
end

-- Icon gadget factory.
function icon_gadget_new(slot, delay, image_path, alignment)
   slot = slot or 'BAT0'
   delay = delay or 10
   image_path = image_path or beautiful.battery_icon
   if image_path == nil then
      error('flaw.battery.icon_gadget_new: could not find image path.')
   end
   alignment = alignment or 'right'

   local battery = BatteryIconGadget:new{
      id = slot,
      status = STATUS_UNKNOWN,
      images = { [STATUS_UNKNOWN] = capi.image(image_path),
                 [STATUS_PLUGGED] = capi.image(image_path),
                 [STATUS_CHARGING] = capi.image(image_path),
                 [STATUS_DISCHARGING] = capi.image(image_path)
              },
      provider = BatteryProviderFactory(slot)
   }
   battery.widget.name = slot
   battery.widget.image = battery.images[STATUS_UNKNOWN]
   battery.widget.alignement = alignment
   battery.provider.set_interval(delay)

   battery:register(delay)
   flaw.gadget.add(battery)

   return battery
end
