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
local io = io
local math = math
local os = os
local string = string
local tonumber = tonumber

local beautiful = require('beautiful')
local naughty = require('naughty')

local awful = {
   button = require("awful.button"),
   util = require("awful.util"),
}

local flaw = {
   helper = require('flaw.helper'),
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider')
}


--- ALSA control gadgets and provider.
--
-- <p>This module contains a provider for ALSA information and two
-- gadgets: a text gadget and an icon gadget.</p>
--
-- <h2>Icon Gadget</h2>
--
-- <p>Assuming you have created a beautiful property to store your
-- ALSA controller icon path, simply add the following line to your
-- configuration to create an ALSA icon gadget.</p>
--
-- <div class='example'>
-- g = flaw.gadget.AlsaIcon(<br/>
-- &nbsp;&nbsp;&nbsp;'0', {}, { image = image(beautiful.sound_icon) })<br/>
-- </div>
--
-- <p>The <code>0</code> parameter is the ID of the card the icon will
-- monitor.</p>
--
-- <p>The ALSA icon gadget specializes the standard icon gadget to
-- allow you to control the volume from the Master channel of the
-- monitored card. The buttons 4 and 5 of the mouse - which should
-- normally be bound to the wheel up and down movements - allow you
-- to change the volume, whereas the left click mutes the channel.</p>
--
-- <h2>Text Gadget</h2>
--
-- <p>The ALSA text gadget allows you to configure the display of the
-- raw provider data. By default, the gadget pattern is
-- <code>'$volume%'</code>.</p>
--
-- <p>To create such a gadget, add the following line to your
-- configuration.</p>
--
-- <div class='example'>
-- g = flaw.gadget.AlsaTextbox('0')
-- </div>
--
-- <p>If you want to provide your own pattern, add the pattern gadget
-- option:</p>
--
-- <div class='example'>
-- g = flaw.gadget.AlsaTextbox(<br/>
-- &nbsp;&nbsp;&nbsp;'0', { pattern = '&lt;span color="#ffffff"&gt;
-- $volume&lt;/span&gt;%($mute)' })
-- </div>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2010, David Soulayrol
module('flaw.alsa')


CHANNEL = 'Master'

--- The ALSA provider prototype.
--
-- <p>The ALSA provider type is set to alsa._NAME. Its data are read
-- using the amix tool</p>
--
-- <p>The ALSA provider data is composed of two fields.</p>
--
-- <ul>
-- <li><code>volume</code><br/>
-- The volume in percent on the Master channel on the monitored card,
-- as a number.</li>
-- <li><code>s_volume</code><br/>
-- A string which represents the current volume in percent of the
-- Master channel on the monitored card, with a visual hint when it is
-- muted. The string is 3 characters long, padded by the left.</li>
-- </ul>
--
-- @class table
-- @name ALSAProvider
ALSAProvider = flaw.provider.CyclicProvider:new{ type = _NAME }

--- Callback for provider refresh.
function ALSAProvider:do_refresh()
   local f = io.popen("amixer -c " .. self.id .. " -- sget " .. CHANNEL)

   -- The following is shamelessly ripped of the Obvious lib.

   -- TODO: In the future, it would be nice to analyse the different
   --       playback channels (see the amix output).
   if f ~= nil then
      local status = f:read('*all')
      if status ~=nil then
         self.data.s_volume = flaw.helper.strings.pad_left(
            string.match(status, '(%d?%d?%d)%%'), 3)
         self.data.volume = tonumber(self.data.s_volume) or 0
         status = string.match(status, '%[(o[^%]]*)%]')
         if status == nil or string.find(status, 'off', 1, true) then
            self.data.s_volume = '---'
         end
      end
      f:close()
   end
end

--- Raise the volume on the Master channel from the monitored card.
function ALSAProvider:raise(offset)
   awful.util.spawn('amixer -q -c ' .. self.id ..
                    ' sset ' .. CHANNEL .. ' ' .. (offset or 1) .. '+', false)
   self:do_refresh()
   self:refresh_gadgets(true)
end

--- Lower the volume on the Master channel from the monitored card.
function ALSAProvider:lower(offset)
   awful.util.spawn('amixer -q -c ' .. self.id ..
                    ' sset ' .. CHANNEL .. ' ' .. (offset or 1) .. '-', false)
   self:do_refresh()
   self:refresh_gadgets(true)
end

--- Mute the Master channel from the monitored card.
function ALSAProvider:mute()
   awful.util.spawn('amixer -q -c ' .. self.id ..
                    ' sset ' .. CHANNEL .. ' toggle', false)
   self:do_refresh()
   self:refresh_gadgets(true)
end

--- A factory for ALSA providers.
--
-- <p>Only one provider is built for a card ID. Created providers are
-- stored in the global provider cache.</p>
--
-- @param  id the identifier of the card for which the new
--         provider should gather information
-- @return a brand new ALSA provider, or an existing one if the
--         given ID was already used to create one.
function provider_factory(id)
   local p = flaw.provider.get(_NAME, id)
   -- Create the provider if necessary.
   if p == nil then
      p = ALSAProvider:new{ id = id, data = { volume = 0, s_volume = '---'} }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget prototype for ALSA status display.
ALSATextGadget = flaw.gadget.TextGadget:new{}

-- Create the wrapped gadget.
function ALSATextGadget:create(wopt)
   flaw.gadget.TextGadget.create(self, wopt)
   self.widget:buttons(
      awful.util.table.join(
         awful.button({ }, 4, function() self.provider:raise() end),
         awful.button({ }, 5, function() self.provider:lower() end),
         awful.button({ }, 1, function() self.provider:mute() end)))
end

flaw.gadget.register.text(
   _M, { delay = 1, pattern = '$s_volume%' }, ALSATextGadget)

-- A progress bar gadget prototype for ALSA status display.
ALSABarGadget = flaw.gadget.BarGadget:new{}

-- Create the wrapped gadget.
function ALSABarGadget:create(wopt)
   flaw.gadget.BarGadget.create(self, wopt)
   self.widget:buttons(
      awful.util.table.join(
         awful.button({ }, 4, function() self.provider:raise() end),
         awful.button({ }, 5, function() self.provider:lower() end),
         awful.button({ }, 1, function() self.provider:mute() end)))
end

flaw.gadget.register.bar(
   _M, { delay = 1, value = 'volume' }, ALSABarGadget)

-- An icon gadget prototype for ALSA status display.
ALSAIconGadget = flaw.gadget.IconGadget:new{}

-- Create the wrapped gadget.
function ALSAIconGadget:create(wopt)
   flaw.gadget.TextGadget.create(self, wopt)
   self.widget:buttons(
      awful.util.table.join(
         awful.button({ }, 4, function() self.provider:raise() end),
         awful.button({ }, 5, function() self.provider:lower() end),
         awful.button({ }, 1, function() self.provider:mute() end)))
end

flaw.gadget.register.icon(_M, { delay = 1 }, ALSAIconGadget)
