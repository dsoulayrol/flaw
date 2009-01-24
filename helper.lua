-- A full OO configuration system for Awesome WM.
-- Licensed under the GPL v3.
-- @author David 'd_rol' Soulayrol &lt;david.soulayrol@gmail.com&gt;

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
      pattern = string.gsub(pattern, '$' .. key, value)
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


-- --{{{ Escape a string
-- function helper.escape(text)
--     if text then
--         text = text:gsub("&", "&amp;")
--         text = text:gsub("<", "&lt;")
--         text = text:gsub(">", "&gt;")
--         text = text:gsub("'", "&apos;")
--         text = text:gsub("\"", "&quot;")
--     end
--     return text
-- end


debug = {}

function debug.display(message)
   naughty.notify{
      title = "DEBUG",
      text = tostring(message),
      timeout = 5
   }
end
