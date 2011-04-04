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
local os = os

local awful = {
   button = require("awful.button"),
   util = require("awful.util"),
}

local flaw = {
   helper = require('flaw.helper'),
   gadget = require('flaw.gadget'),
   provider = require('flaw.provider')
}


--- GMail report gadget and provider.
--
-- <p>This module contains a provider for GMail contents and one text
-- gadget.</p>
--
-- <h2>Text Gadget</h2>
--
-- <p>The GMail status text gadget allows you to configure the
-- display of the raw provider data. By default, the gadget pattern is
-- <code>'$count messages'</code>.</p>
--
-- <p>To create such a gadget, add the following line to your
-- configuration.</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.gmail.textbox')
-- </div>
--
-- <p>If you want to provide your own pattern, add the pattern gadget
-- option:</p>
--
-- <div class='example'>
-- g = flaw.gadget.new('flaw.gmail.textbox',<br/>
-- &nbsp;&nbsp;&nbsp;{ pattern = 'Gmail: &lt;span color="#ffffff"&gt;
-- $count&lt;/span&gt;' })
-- </div>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2010, David Soulayrol
module('flaw.gmail')

--- The gmail provider prototype.
--
-- <p>The gmail provider type is set to gmail._NAME. Its status data
-- are read from the https://mail.google.com/mail/feed/atom/unread"
-- feed using curl. You will very certainly need to provide to curl
-- your GMail credentials (see <i>curl(1)</i>).
--
-- <p>The gmail provider data is composed of three fields.</p>
--
-- <ul>
-- <li><code>count</code><br/>
-- The current number of unread messages.</li>
-- <li><code>mails</code><br/>
-- The unread titles.</li>
-- </ul>
--
-- @class table
-- @name GMailProvider
GMailProvider = flaw.provider.CyclicProvider:new{ type = _NAME }

--- Callback for provider refresh.
function GMailProvider:do_refresh()
   local states = { ROOT = 0, ENTRY = 1, AUTHOR = 2 }
   local depth = states.ROOT
   local current = ''
   local pattern = ''
   local feed = 'https://mail.google.com/mail/feed/atom/unread'
   local f = io.popen("curl --connect-timeout 1 -m 3 -fsn " .. feed)

   if 0 ~= f:seek("end") then

      self.data.timestamp = os.date('%H:%M')
      self.data.count = '0'
      self.data.mails = ''

      f:seek("set")
      for line in f:lines() do
         if depth == states.AUTHOR then
            if line:match("</author>") ~= nil then
               depth = states.ENTRY
            else
               pattern = line:match("<name>(.*)</name>")
               if pattern ~= nil then
                  current = current .. ' (' .. flaw.helper.strings.escape(pattern) .. ')'
               end
            end
         elseif depth == states.ENTRY then
            if line:match("</entry>") ~= nil then
               self.data.mails = self.data.mails .. current .. "\n"
               depth = states.ROOT
            elseif line:match("<author>") ~= nil then
               depth = states.AUTHOR
            else
               pattern = line:match("<title>(.*)</title>")
               if pattern ~= nil then
                  current = flaw.helper.strings.crop(
                     flaw.helper.strings.escape(pattern), 42)

                  -- Remove HTML entities that would be now truncated.
                  local i = current:find("&")
                  if i ~= nil and current:find(";") == nil then
                     current = current:sub(0, i - 1) .. "..."
                  end

                  current = "<i>" .. current .. "</i>"
               end
            end
         elseif depth == states.ROOT then
            if line:match("<entry>") ~= nil then
               depth = states.ENTRY
            else
               self.data.count =
                  line:match("<fullcount>([%d]+)</fullcount>") or self.data.count
            end
         end
      end
   end
   f:close()
end

--- A factory for GMail providers.
--
-- <p>Only one provider is built. It is stored in the global provider
-- cache.</p>
--
-- @return a brand new gmail provider, or an existing one if the
--         given slot was already used to create one.
function provider_factory()
   local p = flaw.provider.get(_NAME, '')
   -- Create the provider if necessary.
   if p == nil then
      p = GMailProvider:new{
         id = '', data = { timestamp = 'N/A', count = "0", mails = '' } }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget prototype for GMail status display.
GMailTextGadget = flaw.gadget.TextGadget:new{}

-- Create the wrapped gadget.
function GMailTextGadget:create(wopt)
   flaw.gadget.TextGadget.create(self, wopt)
   self.widget:buttons(
      awful.util.table.join(
         awful.button({ }, 1, function() self.provider:refresh(self) end)))
end

-- A Text gadget prototype for GMail summary display.
flaw.gadget.register.text(
   _M, { delay = 300, pattern = '$count messages' }, {}, GMailTextGadget)
