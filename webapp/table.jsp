<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    final int LIMIT = 500;
    String requested = request.getParameter("name");
    List<String> tables = new ArrayList<>();
    String current = null;
    List<String> columns = new ArrayList<>();
    List<String[]> rows = new ArrayList<>();
    long total = 0;
    String error = null;
    String hint = null;

    try (Connection conn = openConnection(application)) {
        tables = listTables(conn);

        // Only accept a name that matches a real table (blocks SQL injection)
        if (requested != null) {
            for (String t : tables) {
                if (t.equalsIgnoreCase(requested.trim())) current = t;
            }
        }

        if (current == null) {
            error = (requested == null)
                ? "No table was picked."
                : "There is no table called \"" + requested + "\" in this database.";
            hint = "Pick a table from the list on the left.";
        } else {
            total = countRows(conn, current);
            try (Statement s = conn.createStatement();
                 ResultSet rs = s.executeQuery("SELECT * FROM " + quote(current) + " LIMIT " + LIMIT)) {
                ResultSetMetaData md = rs.getMetaData();
                int n = md.getColumnCount();
                for (int i = 1; i <= n; i++) columns.add(md.getColumnLabel(i));
                while (rs.next()) {
                    String[] r = new String[n];
                    for (int i = 1; i <= n; i++) {
                        Object v = rs.getObject(i);
                        if (v instanceof byte[]) v = "[file, " + ((byte[]) v).length + " bytes]";
                        r[i - 1] = (v == null) ? null : String.valueOf(v);
                    }
                    rows.add(r);
                }
            }
        }
    } catch (Exception e) {
        error = e.getMessage();
        hint = hintFor(e);
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <%@ include file="/WEB-INF/jspf/head.jspf" %>
  <title><%= current != null ? esc(friendly(current)) + " | " : "" %>PetCare Manager</title>
</head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
  <%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

  <main class="main">
    <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>

    <% if (error != null) { %>
      <h1>Table not available</h1>
      <section class="notice">
        <p><%= esc(hint) %></p>
        <p class="notice-detail"><%= esc(error) %></p>
      </section>
    <% } else { %>
      <header class="page-head">
        <h1><%= esc(friendly(current)) %></h1>
        <p class="lede">
          <%= total %> <%= total == 1 ? "row" : "rows" %>
          <% if (total > LIMIT) { %>, showing the first <%= LIMIT %><% } %>
        </p>
      </header>

      <% if (rows.isEmpty()) { %>
        <section class="notice">
          <p>No rows yet. Add records in MySQL Workbench and refresh this page.</p>
        </section>
      <% } else { %>
        <div class="data-wrap" tabindex="0" aria-label="<%= esc(friendly(current)) %> rows">
          <table class="data">
            <thead>
              <tr>
                <% for (String c : columns) { %><th scope="col"><%= esc(c) %></th><% } %>
              </tr>
            </thead>
            <tbody>
              <% for (String[] r : rows) { %>
                <tr>
                  <% for (int i = 0; i < r.length; i++) {
                       String v = r[i];
                       String chip = columns.get(i).toLowerCase().contains("status") ? chipClass(v) : null;
                  %>
                    <td>
                      <% if (v == null) { %><span class="null">empty</span>
                      <% } else if (chip != null) { %><span class="chip <%= chip %>"><%= esc(v) %></span>
                      <% } else { %><%= esc(v) %><% } %>
                    </td>
                  <% } %>
                </tr>
              <% } %>
            </tbody>
          </table>
        </div>
      <% } %>
    <% } %>
  </main>
</div>
</body>
</html>
