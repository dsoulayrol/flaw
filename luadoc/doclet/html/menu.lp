<%
if module_doc then
   from = "modules/"..module_doc.name
elseif file_doc then
   from = "files/.."..file_doc.name
else
   from = ""
end
%>

<!-- Module list -->
<%if not options.nomodules and #doc.modules > 0 then%>
<h1>Modules</h1>
<ul>
<%for _, modulename in ipairs(doc.modules) do
  if module_doc and module_doc.name == modulename then%>
    <li><strong><%=modulename%></strong></li>
  <%else%>
    <li><a href="<%=luadoc.doclet.html.module_link(modulename, doc, from)%>"
      ><%=modulename%></a></li>
  <%end%>
<%end%>
</ul>
<%end%>
