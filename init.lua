-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

local helper = require('flaw.helper')
local gadget = require('flaw.gadget')
local provider = require('flaw.provider')

local battery = require('flaw.battery')
local network = require('flaw.network')
local cpu = require('flaw.cpu')

--- Fully Loaded AWesome package.
module("flaw")
