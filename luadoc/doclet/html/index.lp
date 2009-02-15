<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
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
            <b>flaw</b> is a LUA object oriented package providing
            mechanisms to easily handle the configuration and the
            management of awesome widgets. <b>flaw</b> is aimed at
            being simple and resources efficient. To achieve these
            goals, it minimises system resources access and provides
            asynchronous events capabilities. The core <b>flaw</b>
            concepts are detailed in
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
          <p>
            To start using <b>flaw</b>, simply add the following
            requirement at the top of your awesome configuration
            file. You will find many code samples in the module
            descriptions.
          </p>
          <div class='example'>require('flaw')</div>
          <p>
            <b>flaw</b> is licensed under
            the <a href="http://www.gnu.org/licenses/gpl.html">GNU
            General Public License v3</a>.
          </p>

          <%if not options.nomodules and #doc.modules > 0 then%>
          <h2>Modules</h2>
          <table class="module_list">
            <!--<tr><td colspan="2">Modules</td></tr>-->
            <%for _, modulename in ipairs(doc.modules) do%>
	    <tr>
	      <td class="name"><a href="<%=luadoc.doclet.html.module_link(modulename, doc)%>"><%=modulename%></a></td>
	      <td class="summary"><%=doc.modules[modulename].summary%></td>
	    </tr>
            <%end%>
          </table>
          <%end%>

        </div> <!-- id="content" -->
      </div> <!-- id="main" -->

      <div id="footer"><%=luadoc.doclet.html.include("footer.lp")%></div>
    </div> <!-- id="container" -->
  </body>
</html>
