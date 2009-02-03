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


-- Essential modules.
local gadget = require('flaw.gadget')
local provider = require('flaw.provider')
local event = require('flaw.event')
local helper = require('flaw.helper')

-- Implementation modules.
local battery = require('flaw.battery')
local network = require('flaw.network')
local cpu = require('flaw.cpu')

--- The <i>fully loaded awesome</i> package.
--
-- <br/><br/>
-- <b>flaw</b> is a LUA object oriented package providing mechanisms
-- to easily handle the configuration and the management of awesome
-- widgets.
--
-- <br/><br/>
-- <b>flaw</b> is aimed at being simple and resources efficient. To
-- achieve these goals, it minimises system resources access and
-- provides asynchronous events capabilities. The core <b>flaw</b>
-- concepts are detailed in the <a
-- href='flaw.gadget.html'><i>gadget</i></a>, <a
-- href='flaw.provider.html'><i>provider</i></a> and <a
-- href='flaw.event.html'><i>event</i></a> modules.
--
-- <br/><br/>
-- <b>flaw</b> provides many gadgets for common system information
-- (like CPU or memory activity). It also proposes a simple API to
-- extend all core objects, allowing you to write new system resources
-- interfaces or to automate the configuration of new widgets.
--
-- <br/><br/>
-- To start using <b>flaw</b>, simply add the following requirement
-- at the top of your awesome configuration file.
-- <br/><code>&nbsp;&nbsp;&nbsp;require('flaw')</code>
--
-- <br/><br/>
-- You will find many code samples in the module descriptions.
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module("flaw")
