-- flaw, a Lua OO management framework for Awesome WM widgets.
-- Copyright (C) 2009, 2010 David Soulayrol <david.soulayrol AT gmail DOT net>

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
local math = math
local pairs = pairs
local string = string
local tostring = tostring

local table = require('table')

local naughty = require('naughty')
local beautiful = require('beautiful')

-- Utilities for Flaw.
--
-- This module mainly contains utilities borrowed and improved from
-- wicked and other scripts found on the Awesome wiki. Many thanks to
-- all he wiki contributers.
module('flaw.helper')

local unities = { 'b', 'Kb', 'Mb', 'Gb', 'Tb' }

file = {}

-- Append the given string to a tempporary log file.
-- @param line the line to write down.
function file.log(line)
   if line ~= nil then
      local log = io.open('/tmp/awesome_rc.log', 'a')
      log:write(os.date('%c\t') .. tostring(line) .. '\n')
      log:close()
   end
end

-- Load a file with line formatted as "name: value".
function file.load_state_file(path, name, t)
   local f = io.open(path .. '/' .. name)

   if f ~= nil then
      local prefix = name:lower() .. '_'
      local line = nil
      repeat
         line = f:read()
         if line then
            n, v = line:match('([%a ]+):%s+([%w ]+)')
            if n ~= nil and v ~= nil then
               t[prefix .. n:gsub(' ', '_'):lower()] = v:lower()
            end
         end
      until line == nil
      f:close()
      return true
   end
   return false
end

format = {}

function format.set_bg(color, text)
    return '<bg color="'..color..'" />'..text
end
 
function format.set_fg(color, text)
    return '<span color="'..color..'">'..text..'</span>'
end
 
function format.set_bg_fg(bgcolor, fgcolor, text)
    return '<bg color="'..bgcolor..'" /><span color="'..fgcolor..'">'..text..'</span>'
end
 
function format.set_font(font, text)
    return '<span font_desc="'..font..'">'..text..'</span>'
end

strings = {}

-- Split the given string by whitespaces.
-- @param str the string to split.

function strings.split(str)
   str = str or ''
   values = {}

   local start = 1
   while true do
      local splitstart, splitend = string.find(str, ' ', start)
      local token = string.sub(str, start, splitstart and splitstart - 1 or nil)
      if token:gsub(' ','') ~= '' then
         table.insert(values, token)
      end
      if splitstart == nil then break end
      
      start = splitend+1
      splitstart, splitend = string.find(str, ' ', start)
   end

   return values
end

-- Crop the given string to the given maximum width.
-- If string is too large, the right-most part is replaced by an ellipsis.
function strings.crop(str, width)
   str = str or ''
   local len = str:len()
   width = width or len
   if width < 3 then
      str = ''
   elseif len > width then
      str = str:sub(1, width - 3) .. '...'
   end
   return str
end

-- Force a fixed width on a string with spaces.
function strings.pad_string(str, width)
   str = str or ''
   local len = str:len()
   width = width or len
   if width > len then
      for i = 1, width - len do
         str = str .. ' '
      end
   else
      str = str:sub(0, width)
   end
   return str
end

-- Pad a number to a minimum amount of digits.
-- The result is wrong for numbers between 0 and 1.
function strings.pad_number(number, padding)
   number = number or 0
   local str = tostring(number) or ''
   padding = padding or str:len()
   for i = 1, padding do
      if math.floor(number / math.pow(10, (i - 1))) == 0 then
         str = '0' .. str
      end
   end
   if number == 0 then
      str = str:sub(2)
   end
   return str
end

-- Fill in a string with given arguments.
function strings.format(pattern, args)
   pattern = pattern or ''
   args = args or {}
   for key, value in pairs(args) do
      if key ~= nil and value ~= nil then
         pattern = string.gsub(pattern, '$' .. key, value)
      end
   end
   return pattern
end

-- Convert amount of bytes to string.
function strings.format_bytes(bytes, padding)
   bytes = bytes and tonumber(bytes) or ''
   padding = padding
   local sign = 1
   while bytes / 1024 > 1 and unities[sign + 1] ~= nil do
      bytes = bytes / 1024
      sign = sign + 1
   end
   bytes = math.floor(bytes * 10)/10
   if padding then
      bytes = pad_number(bytes * 10, padding + 1)
      bytes = bytes:sub(1, bytes:len() - 1) .. '.' .. bytes:sub(bytes:len())
   end
   return tostring(bytes) .. unities[sign]
end

-- Strip left spaces on a string.
function strings.lstrip(str)
   return str:match("^[ \t]*(.*)$")
end

-- Strip spaces on a string.
function strings.strip(str)
   return str:match("^[ \t]*(.-)[ \t]*$")
end

-- Strip right spaces on a string.
function strings.rstrip(str)
   return str:match("^(.-)[ \t]*$")
end

-- Escape a string
function strings.escape(text)
   local xml_entities = {
      ["\""] = "&quot;",
      ["&"]  = "&amp;",
      ["'"]  = "&apos;",
      ["<"]  = "&lt;",
      [">"]  = "&gt;"
   }
   return text and text:gsub("[\"&'<>]", xml_entities)
end

function round(n, p)
  local m = 10^(p or 0)
  return math.floor(m*n + 0.5)/m
end

debug = {}

function debug.display(message)
   naughty.notify{
      title = "DEBUG",
      text = tostring(message),
      timeout = 5
   }
end

function debug.warn(message)
   io.stderr:write(os.date('%A %d %B %H:%M:%S') .. ' WARNING: ' .. tostring(message) .. '\n')
end

function debug.error(message)
   io.stderr:write(os.date('%A %d %B %H:%M:%S') .. ' ERROR: ' .. tostring(message) .. '\n')
end
