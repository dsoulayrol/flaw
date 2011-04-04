-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Flaw Tests
require("flaw")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- Gadgets population.
local gadgets = {}

-- Calendar
gadgets.calendar = flaw.gadget.text.calendar(
   '', { clock_format = ' | %a %d %B - <span color="' .. beautiful.fg_focus .. '">%H:%M</span>' })

-- Client title
gadgets.title = flaw.gadget.text.title(
   '', { pattern = ' | <b><small>$title</small></b>' })

-- GMail
gadgets.gmail = flaw.gadget.text.gmail(
   '', { pattern = ' | GMail: <span color="' .. beautiful.fg_focus .. '">$count</span> ' })
gadgets.gmail:set_tooltip('Unread messages at $timestamp:\n$mails')

-- ALSA
-- gadgets.alsa_icon = flaw.gadget.AlsaIcon(
--    'alsa', {}, { image = image(beautiful.icon_cpu) })

gadgets.alsa = flaw.gadget.text.alsa('0', { pattern = ' | Vol.:$s_volume% ' })
gadgets.alsa_bar = flaw.gadget.bar.alsa('0')
gadgets.alsa_bar.hull:set_vertical(true)
gadgets.alsa_bar.hull:set_height(18)
gadgets.alsa_bar.hull:set_width(12)
-- gadgets.alsa_bar.hull:set_ticks(true)
-- gadgets.alsa_bar.hull:set_ticks_size(2)
gadgets.alsa_bar.hull:set_background_color(beautiful.bg_normal)
gadgets.alsa_bar.hull:set_gradient_colors(
   { beautiful.fg_normal, beautiful.fg_focus, beautiful.fg_urgent})

-- Create CPU, CPUfreq monitor
-- gadgets.cpu_icon = flaw.gadget.CPUIcon(
--    'cpu', {}, { image = image(beautiful.icon_cpu) })

gadgets.cpu_graph = flaw.gadget.graph.cpu(
   'cpu', {}, { width = 60, height = 18 })
gadgets.cpu_graph.hull:set_color(beautiful.fg_normal)
gadgets.cpu_graph.hull:set_border_color(beautiful.fg_normal)
gadgets.cpu_graph.hull:set_background_color(beautiful.bg_normal)

-- Create network monitor
-- gadgets.net_icon = flaw.gadget.NetIcon(
--    'eth0', {}, { image = image(beautiful.icon_net) })

gadgets.net_graph = flaw.gadget.graph.network(
   'eth0', {}, { width = 60, height = 18 })
gadgets.net_graph.hull:set_color(beautiful.fg_normal)
gadgets.net_graph.hull:set_border_color(beautiful.fg_normal)
gadgets.net_graph.hull:set_background_color(beautiful.bg_normal)

-- gadgets.memory_box = flaw.gadget.new('flaw.memory.textbox', '')

-- Create battery monitor
if flaw.battery ~= nil then
   gadgets.battery_icon = flaw.gadget.icon.battery(
      'BAT0',
      {
         my_icons = {
            image(beautiful.icon_battery_low),
            image(beautiful.icon_battery_mid),
            image(beautiful.icon_battery_full)
         },
         my_load_icon = image(beautiful.icon_battery_plugged),
         my_update = function(self)
                        if self.provider.data.st_symbol == flaw.battery.STATUS_CHARGING then
                           self.widget.image = self.my_load_icon
                        else
                           self.widget.image = self.my_icons[math.floor(self.provider.data.load / 30) + 1]
                        end
                     end
      },
      {
         image = image(beautiful.icon_battery_full)
      }
   )
   gadgets.battery_icon:add_event(
      flaw.event.EdgeTrigger:new{ condition = function(d) return d.load < 60 end },
      function (g) g:my_update() end
   )
   gadgets.battery_icon:add_event(
      flaw.event.EdgeTrigger:new{ condition = function(d) return d.load < 30 end },
      function (g) g:my_update() end
   )
   gadgets.battery_icon:add_event(
      flaw.event.EdgeTrigger:new{
         condition = function(d) return d.st_symbol == flaw.battery.STATUS_CHARGING end },
      function (g) g:my_update() end
   )
   gadgets.battery_icon:add_event(
      flaw.event.LatchTrigger:new{condition = function(d) return d.load < 10 end },
      function(g) naughty.notify{
            title = "Battery Warning",
            text = "Battery low! " .. g.provider.data.load .. "% left!",
            timeout = 10,
            position = "top_right",
            fg = beautiful.fg_focus,
            bg = beautiful.bg_focus} end
   )

   gadgets.battery_box = flaw.gadget.text.battery(
      'BAT0',
      { pattern = '<span color="#99aa99">$load</span>% $time' } )
   gadgets.battery_box:add_event(
      flaw.event.LatchTrigger:new{condition = function(d) return d.load < 60 end },
      function(g) g.pattern = '<span color="#ffffff">$load</span>%' end
   )
   gadgets.battery_box:add_event(
      flaw.event.LatchTrigger:new{condition = function(d) return d.load < 30 end },
      function(g) g.pattern = '<span color="#ff6565">$load</span>%' end
   )
end

-- Create wifi monitor
-- local w_wifi_widget = wifi.widget_new('wlan0')

-- Create sound monitor
-- local w_sound_widget = sound.widget_new()


-- This is used later as the default terminal and editor to run.
terminal = "x-terminal-emulator"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag({ 1, 2, 3, 4, 5, 6, 7, 8, 9 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox

-- Create a wibox for each screen and add it
mywibox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )

for s = 1, screen.count() do
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            mylauncher,
            mytaglist[s],

            gadgets.calendar.widget,
            gadgets.gmail.widget,
            gadgets.alsa.widget,
            gadgets.alsa_bar.widget,
--            gadgets.cpu_icon.widget or nil,
            gadgets.cpu_graph.widget or nil,
--            gadgets.net_icon.widget or nil,
            gadgets.net_graph.widget or nil,
            gadgets.battery_box and gadgets.battery_box.widget or nil,
            gadgets.battery_icon and gadgets.battery_icon.widget or nil,
            gadgets.title.widget,

            layout = awful.widget.layout.horizontal.leftright
        },
        mylayoutbox[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

flaw.check_modules()
