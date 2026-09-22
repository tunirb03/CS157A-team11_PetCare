<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    List<String> tables = new ArrayList<>();
    Map<String, Long> counts = new LinkedHashMap<>();
    List<String[]> pets = new ArrayList<>();   // each entry: name, details
    String petTable = null;
    String current = null;
    String dbName = null;
    String error = null;
    String hint = null;
    long totalRows = 0;

    try (Connection conn = openConnection(application)) {
        dbName = conn.getCatalog();
        tables = listTables(conn);
        for (String t : tables) {
            long n = countRows(conn, t);
            counts.put(t, n);
            totalRows += n;
            if (t.equalsIgnoreCase("pet") || t.equalsIgnoreCase("pets")) petTable = t;
        }

        // Pets list: reads the Pet table if there is one
        if (petTable != null) {
            try (Statement s = conn.createStatement();
                 ResultSet rs = s.executeQuery("SELECT * FROM " + quote(petTable) + " LIMIT 50")) {
                ResultSetMetaData md = rs.getMetaData();
                int n = md.getColumnCount();
                int nameCol = -1, speciesCol = -1, breedCol = -1;
                for (int i = 1; i <= n; i++) {
                    String c = md.getColumnLabel(i).toLowerCase();
                    if (nameCol < 0 && (c.equals("name") || c.equals("pet_name") || c.equals("petname"))) nameCol = i;
                    if (speciesCol < 0 && c.contains("species")) speciesCol = i;
                    if (breedCol < 0 && c.contains("breed")) breedCol = i;
                }
                if (nameCol < 0) {
                    for (int i = 1; i <= n; i++) {
                        if (md.getColumnLabel(i).toLowerCase().contains("name")) { nameCol = i; break; }
                    }
                }
                if (nameCol < 0) nameCol = (n > 1) ? 2 : 1;

                while (rs.next()) {
                    String name = rs.getString(nameCol);
                    List<String> bits = new ArrayList<>();
                    if (speciesCol > 0 && rs.getString(speciesCol) != null) bits.add(rs.getString(speciesCol));
                    if (breedCol > 0 && rs.getString(breedCol) != null) bits.add(rs.getString(breedCol));
                    pets.add(new String[] { name == null ? "Unnamed pet" : name, String.join(", ", bits) });
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
  <title>Dashboard | PetCare Manager</title>
</head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
  <%@ include file="/WEB-INF/jspf/sidebar.jspf" %>

  <main class="main">
    <header class="page-head">
      <h1>Your dashboard</h1>
      <% if (error == null) { %>
        <div class="tag" role="status">
          <span class="tag-label">Connected to</span>
          <strong><%= esc(dbName) %></strong>
        </div>
      <% } else { %>
        <div class="tag tag-error" role="alert">
          <span class="tag-label">Not connected</span>
          <strong>MySQL</strong>
        </div>
      <% } %>
    </header>

    <% if (error != null) { %>
      <section class="notice">
        <h2>Tomcat could not load the database</h2>
        <p><%= esc(hint) %></p>
        <p class="notice-detail">MySQL said: <%= esc(error) %></p>
      </section>
    <% } else { %>

      <section class="pets">
        <img class="pets-dog" src="assets/img/dog.png" alt="A happy cartoon dog sitting next to a tennis ball">
        <div class="pets-body">
          <h2>List of pets you know</h2>
          <% if (petTable == null) { %>
            <p class="pets-empty">No pets yet. Once you add a Pet table in MySQL Workbench, your pets will show up here.</p>
          <% } else if (pets.isEmpty()) { %>
            <p class="pets-empty">No pets yet. Add a pet in MySQL Workbench and refresh this page.</p>
          <% } else { %>
            <ul class="pet-list">
              <% for (String[] p : pets) { %>
                <li>
                  <span class="pet-name"><%= esc(p[0]) %></span>
                  <% if (!p[1].isEmpty()) { %><span class="pet-detail"><%= esc(p[1]) %></span><% } %>
                </li>
              <% } %>
            </ul>
            <a class="pets-all" href="table.jsp?name=<%= url(petTable) %>">See all pet details</a>
          <% } %>
        </div>
      </section>

      <h2 class="section-title">Your tables</h2>
      <% if (tables.isEmpty()) { %>
        <section class="notice">
          <p>This database has no tables yet. Run your CREATE TABLE script in MySQL Workbench, then refresh this page.</p>
        </section>
      <% } else { %>
        <p class="lede"><%= tables.size() %> <%= tables.size() == 1 ? "table" : "tables" %> and <%= totalRows %> <%= totalRows == 1 ? "record" : "records" %> in total.</p>
        <ul class="ledger">
          <% for (Map.Entry<String, Long> e : counts.entrySet()) { %>
            <li>
              <a href="table.jsp?name=<%= url(e.getKey()) %>">
                <span class="ledger-name"><%= esc(friendly(e.getKey())) %></span>
                <span class="ledger-count"><%= e.getValue() %> <%= e.getValue() == 1 ? "row" : "rows" %></span>
              </a>
            </li>
          <% } %>
        </ul>
      <% } %>
    <% } %>
  </main>
</div>
</body>
</html>
