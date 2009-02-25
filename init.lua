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
local memory = require('flaw.memory')

--- The fully loaded awesome package.
--
-- <p><b>flaw</b> package is composed of core modules, which provide
-- the raw mechanisms and utilities, and implementation modules which
-- build upon this core to propose interesting gadgets and
-- information. Users normally start using <b>flaw</b> by looking to
-- implementation modules.</p>
--
-- @author David Soulayrol &lt;david.soulayrol AT gmail DOT com&gt;
-- @copyright 2009, David Soulayrol
module("flaw")
