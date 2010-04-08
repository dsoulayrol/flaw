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

local string = {
    find = string.find,
    match = string.match
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
-- <p>The gmail provider data is composed of two fields.</p>
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
GMailProvider = flaw.provider.Provider:new{ type = _NAME }

--- Callback for provider refresh.
function GMailProvider:do_refresh()
   local run_once = nil
   local feed = {
      "https://mail.google.com/mail/feed/atom/unread",
      "Gmail %- Label"
   }
   local f = io.popen("curl --connect-timeout 1 -m 3 -fsn " .. feed[1])

   -- TODO: to improve to retrieve the author of the mail.
   self.data.count = '0'
   for line in f:lines() do
      self.data.count =
         string.match(line, "<fullcount>([%d]+)</fullcount>") or self.data.count

      -- Find subject tags
      local title = string.match(line, "<title>(.*)</title>")
      -- If the subject changed then break out of the loop
      if title ~= nil and not string.find(title, feed[2]) then
         -- Sanitize the subject and store it.
         if run_once == nil then
            self.data.mails = flaw.helper.escape(title)
            run_once = "ran"
         else
            self.data.mails = self.data.mails .. "\n" .. flaw.helper.escape(title)
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
function GMailProviderFactory()
   local p = flaw.provider.get(_NAME, '')
   -- Create the provider if necessary.
   if p == nil then
      p = GMailProvider:new{
         id = '', data = { count = "0", subjects = {} } }
      flaw.provider.add(p)
   end
   return p
end

-- A Text gadget prototype for GMail summary display.
flaw.gadget.register(
   flaw.gadget.TextGadget:new{ type = _NAME .. '.textbox' },
   GMailProviderFactory,
   { delay = 300, pattern = '$count messages' }
)
