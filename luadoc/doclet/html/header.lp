<%
if module_doc then
   from = "modules/"..module_doc.name
elseif file_doc then
   from = "files/.."..file_doc.name
else
   from = ""
end
%>

<div id="product_logo"></div>
<div id="product_name">
  <a href="<%=luadoc.doclet.html.link("index.html", from)%>">flaw</a></div>
<div id="product_description">
  A Lua OO management framework for Awesome WM widgets.</div>
