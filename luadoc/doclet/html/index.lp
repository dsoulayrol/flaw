<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
          "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Flaw Reference Manual</title>
    <link rel="stylesheet" href="<%=luadoc.doclet.html.link("luadoc.css")%>" type="text/css" />
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  </head>

  <body>
    <div id="container">
      <div id="header"><%=luadoc.doclet.html.include("header.lp")%></div>
      <div id="main">
        <div id="content">
          <h2>Introduction</h2>
          <p>
            <b>flaw</b> is a <a href="http://lua.org">Lua</a> object
            oriented package providing mechanisms to easily handle the
            configuration and the management
            of <a href="http://awesome.naquadah.org">awesome</a>
            widgets. <b>flaw</b> is aimed at being simple and
            resources efficient. To achieve these goals, it minimises
            system resources access and provides asynchronous events
            capabilities. The core <b>flaw</b> concepts are detailed
            in
            the <a href="<%=luadoc.doclet.html.module_link('flaw.gadget',
            doc)%>" >gadget</a>,
            <a href="<%=luadoc.doclet.html.module_link('flaw.provider',
               doc)%>" >provider</a> and
            <a href="<%=luadoc.doclet.html.module_link('flaw.event',
                   doc)%>" >event</a> modules.
          </p>
          <p>
            <b>flaw</b> provides many gadgets for common system
            information (like CPU or memory activity). It also
            proposes a simple API to extend all core objects, allowing
            you to write new system resources interfaces or to
            automate the configuration of new widgets.
          </p>

          <h2>Installation</h2>
          <p>
            The source code of <b>flaw</b> is hosted
            on <a href="http://github.com">GitHub</a> and can be
            browsed <a href="http://github.com/dsoulayrol/flaw">here</a>. There
            is neither archive nor stable release at this time.
          </p>
          <p>
            The only dependency of <b>flaw</b>, besides the need to
            run it inside <b>awesome</b> of course, is
            the <b>lua-filesystem</b> package which can be found
            at <a href="http://luaforge.net/projects/luafilesystem">LuaForge.net</a>.
          </p>
          <%if not options.nomodules and #doc.modules > 0 then%>

          <h2>Documentation</h2>
          <table class="module_list">
            <tr><th colspan="2">Modules</th></tr>
            <%for _, modulename in ipairs(doc.modules) do%>
	    <tr>
	      <td class="name"><a href="<%=luadoc.doclet.html.module_link(modulename, doc)%>"><%=modulename%></a></td>
	      <td class="summary"><%=doc.modules[modulename].summary%></td>
	    </tr>
            <%end%>
          </table>
          <%end%>

          <h2>Credits and License</h2>
          <p>
            The <a href="http://awesome.naquadah.org/wiki/Main_Page">awesome
            wiki</a> proposes a lot of more
            common <a href="http://awesome.naquadah.org/wiki/Main_Page#Lua_extensions">Lua
            extensions</a>. Though their design and target differ, all
            of them provide similar information like CPU or network
            status and share some algorithms. Thus, the core functions
            of many modules developped in <b>flaw</b> come
            from <b>wicked</b> or <b>vicious</b>. Many thanks to all
            the contributors to these Lua extensions.
          </p>
          <p>
            <b>flaw</b> is licensed under
            the <a href="http://www.gnu.org/licenses/gpl.html">GNU
            General Public License v3</a>.
          </p>

        </div> <!-- id="content" -->
      </div> <!-- id="main" -->

      <div id="footer">
        <p>
          <a href="http://validator.w3.org/check?uri=referer">
            <img src="http://www.w3.org/Icons/valid-xhtml11-blue" alt="Valid XHTML 1.1" height="31" width="88" />
          </a>
        </p>
      </div>
    </div> <!-- id="container" -->
  </body>
</html>
