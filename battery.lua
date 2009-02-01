-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

-- Grab environment.
local io = io
local math = math
local tonumber = tonumber
local tostring = tostring -- For DEBUG only.

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
STATUS_UNKNOWN = '='
STATUS_PLUGGED = '(A/C)'
STATUS_CHARGING = '^'
STATUS_DISCHARGING = 'v'

-- The battery provider.
BatteryProvider = flaw.provider.Provider:new{ type = _NAME, data = {} }
BatteryProvider.data.load = '0'
BatteryProvider.data.status = ''

-- Callback for provider refresh.
-- See Provider:do_refresh.
function BatteryProvider:do_refresh()
   local load
   local raw_status
   local fcur = io.open("/sys/class/power_supply/" .. self.id .. "/charge_now")
   local fcap = io.open("/sys/class/power_supply/" .. self.id .. "/charge_full")
   local f_status = io.open("/sys/class/power_supply/" .. self.id .. "/status")
   if fcur ~= nil and fcap ~= nil then
      load = math.floor(fcur:read() * 100 / fcap:read())
      if load > 100 then load = 100 end
      fcur:close()
      fcap:close()
   end
   if f_status ~= nil then
      raw_status = f_status:read()
      f_status:close()
   end

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
               text = "Battery low! " .. load .. "% left!",
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
flaw.gadget.register(
   flaw.gadget.TextGadget:new{ type = _NAME .. '.textbox' },
   BatteryProviderFactory,
   { pattern = '$load% $status' }
)

-- An icon gadget for battery status display.
BatteryIconGadget = flaw.gadget.IconGadget:new{ type = _NAME .. '.imagebox' }

function BatteryIconGadget:update()
   if self.provider ~= nil then
      self.provider:refresh()
      if self.provider.data.status ~= self.status then
         self.status = self.provider.data.status
         self.widget.image = self.images[self.status]
      end
   end
end

flaw.gadget.register(
   BatteryIconGadget,
   BatteryProviderFactory,
   { status = STATUS_UNKNOWN }
)
