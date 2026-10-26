<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    if ("logout".equals(request.getParameter("action"))) {
        session.invalidate(); response.sendRedirect("index.jsp"); return;
    }
    boolean sitter = isSitter(session);
    int userId = (Integer) session.getAttribute("userId");
    String dbName = null, error = null;
    int firstCount = 0, secondCount = 0;
    try (Connection conn = openConnection(application)) {
        dbName = conn.getCatalog();
        String q1 = sitter ? "SELECT COUNT(*) FROM Service WHERE SitterID=?" : "SELECT COUNT(*) FROM Pet WHERE OwnerID=?";
        String q2 = sitter ? "SELECT COUNT(*) FROM Booking WHERE SitterID=?" : "SELECT COUNT(*) FROM Booking WHERE ClientID=?";
        try (PreparedStatement p = conn.prepareStatement(q1)) {
            p.setInt(1, userId); try (ResultSet r = p.executeQuery()) { if (r.next()) firstCount = r.getInt(1); }
        }
        try (PreparedStatement p = conn.prepareStatement(q2)) {
            p.setInt(1, userId); try (ResultSet r = p.executeQuery()) { if (r.next()) secondCount = r.getInt(1); }
        }
    } catch (Exception e) { error = e.getMessage(); }
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Dashboard | PetCare Manager</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
  <%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
  <main class="main">
    <header class="page-head">
      <div>
        <h1>Welcome, <%= esc(session.getAttribute("userName")) %></h1>
        <p class="lede"><%= sitter ? "Pet sitter workspace" : "Pet owner workspace" %></p>
      </div>
      <% if (error == null) { %><div class="tag"><span class="tag-label">Connected to</span><strong><%= esc(dbName) %></strong></div>
      <% } else { %><div class="tag tag-error"><span class="tag-label">Database error</span><strong>MySQL</strong></div><% } %>
    </header>
    <% if (error != null) { %>
      <section class="notice"><h2>Database connection problem</h2><p>Please check the database settings.</p><p class="notice-detail"><%= esc(error) %></p></section>
    <% } else if (sitter) { %>
      <section class="ledger">
        <a class="btn btn-primary" href="services.jsp">Manage my services</a>
        <a class="btn btn-primary" href="bookings.jsp">Manage bookings</a>
        <a class="btn btn-outline" href="payments.jsp">View payments</a>
        <a class="btn btn-outline" href="reviews.jsp">Reviews</a>
      </section>
      <section class="pets"><div class="pets-body"><h2>Sitter overview</h2>
        <p>You currently manage <strong><%= firstCount %></strong> service<%= firstCount == 1 ? "" : "s" %>.</p>
        <p>You have <strong><%= secondCount %></strong> booking<%= secondCount == 1 ? "" : "s" %> assigned to you.</p>
      </div></section>
    <% } else { %>
      <section class="ledger">
        <a class="btn btn-primary" href="pets.jsp">Manage my pets</a>
        <a class="btn btn-primary" href="services.jsp">Browse services</a>
        <a class="btn btn-primary" href="bookings.jsp">My bookings</a>
        <a class="btn btn-outline" href="payments.jsp">My payments</a>
        <a class="btn btn-outline" href="reviews.jsp">My reviews</a>
      </section>
      <section class="pets"><div class="pets-body"><h2>Owner overview</h2>
        <p>You have <strong><%= firstCount %></strong> pet<%= firstCount == 1 ? "" : "s" %> saved.</p>
        <p>You have <strong><%= secondCount %></strong> booking<%= secondCount == 1 ? "" : "s" %>.</p>
      </div></section>
    <% } %>
  </main>
</div>
</body>
</html>
