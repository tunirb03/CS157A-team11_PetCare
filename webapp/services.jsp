<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    boolean sitterUser = isSitter(session);
    int userId = (Integer) session.getAttribute("userId");
    String message = null, error = null;

    if ("POST".equalsIgnoreCase(request.getMethod()) && sitterUser) {
        String action = request.getParameter("action");
        int id = intParam(request.getParameter("id"), 0);
        String name = text(request.getParameter("name"));
        String category = pick(request.getParameter("category"), SERVICE_CATEGORIES);
        double price = doubleParam(request.getParameter("price"), -1);
        int minutes = intParam(request.getParameter("duration"), 0);
        int capacity = intParam(request.getParameter("capacity"), 0);
        try (Connection conn = openConnection(application)) {
            if (name == null || category == null || price < 0 || minutes < 1 || capacity < 1)
                throw new Exception("Please fill in a name, a category, a price of 0 or more, and a duration and capacity of at least 1.");
            if ("add".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Service(SitterID,ServiceName,Category,Description,Price,DurationMinutes,Capacity) VALUES(?,?,?,?,?,?,?)")) {
                    ps.setInt(1, userId); ps.setString(2, name); ps.setString(3, category);
                    ps.setString(4, text(request.getParameter("description"))); ps.setDouble(5, price);
                    ps.setInt(6, minutes); ps.setInt(7, capacity);
                    ps.executeUpdate();
                }
                audit(conn, userId, "ADD_SERVICE", "Added service " + name);
                message = "Service added.";
            } else if ("update".equals(action)) {
                String availability = request.getParameter("active") != null ? "AVAILABLE" : "UNAVAILABLE";
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Service SET ServiceName=?,Category=?,Description=?,Price=?,DurationMinutes=?,Capacity=?,AvailabilityStatus=? " +
                        "WHERE ServiceID=? AND SitterID=?")) {
                    ps.setString(1, name); ps.setString(2, category); ps.setString(3, text(request.getParameter("description")));
                    ps.setDouble(4, price); ps.setInt(5, minutes); ps.setInt(6, capacity); ps.setString(7, availability);
                    ps.setInt(8, id); ps.setInt(9, userId);
                    if (ps.executeUpdate() == 0) throw new Exception("That service was not found.");
                }
                audit(conn, userId, "UPDATE_SERVICE", "Updated service " + id + " (" + name + "), now " + availability);
                message = "Service updated.";
            }
        } catch (Exception e) { error = e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Services | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1><%= sitterUser ? "Manage my services" : "Browse services" %></h1>
  <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>

  <% if (sitterUser) { %>
  <section class="panel">
    <h2>Add a service</h2>
    <form method="post" class="form-grid">
      <input type="hidden" name="action" value="add">
      <label>Name <input name="name" maxlength="100" required></label>
      <label>Category <select name="category" required><%= options(SERVICE_CATEGORIES, null) %></select></label>
      <label>Price ($) <input name="price" type="number" min="0" step="0.01" required></label>
      <label>Duration (minutes) <input name="duration" type="number" min="1" value="30" required></label>
      <label>Bookings at once <input name="capacity" type="number" min="1" value="1" required></label>
      <label class="wide">Description <textarea name="description" maxlength="255"></textarea></label>
      <div class="wide"><button class="btn btn-primary" type="submit">Add service</button></div>
    </form>
  </section>
  <% } %>

  <h2 class="section-title"><%= sitterUser ? "My services" : "Available services" %></h2>
  <div class="cards">
<%
    String serviceSql = sitterUser
        ? "SELECT sv.*, st.BusinessName, st.ServiceArea FROM Service sv JOIN Sitter st ON st.UserID=sv.SitterID WHERE sv.SitterID=? ORDER BY sv.ServiceName"
        : "SELECT sv.*, st.BusinessName, st.ServiceArea FROM Service sv JOIN Sitter st ON st.UserID=sv.SitterID WHERE sv.AvailabilityStatus='AVAILABLE' ORDER BY sv.ServiceName";
    int serviceCount = 0;
    try (Connection conn = openConnection(application); PreparedStatement ps = conn.prepareStatement(serviceSql)) {
        if (sitterUser) ps.setInt(1, userId);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                serviceCount++;
                boolean available = "AVAILABLE".equals(rs.getString("AvailabilityStatus"));
%>
    <article class="card">
      <h3><%= esc(rs.getString("ServiceName")) %>
        <% if (sitterUser && !available) { %><span class="chip chip-cancelled">Inactive</span><% } %></h3>
      <p class="card-meta">
        <%= esc(label(rs.getString("Category"))) %> · $<%= String.format("%.2f", rs.getDouble("Price")) %>
        · <%= rs.getInt("DurationMinutes") %> minutes · up to <%= rs.getInt("Capacity") %> booking<%= rs.getInt("Capacity") == 1 ? "" : "s" %> at a time
      </p>
      <% if (!sitterUser) { %><p>Offered by <strong><%= esc(rs.getString("BusinessName")) %></strong><% if (rs.getString("ServiceArea") != null) { %> in <%= esc(rs.getString("ServiceArea")) %><% } %></p><% } %>
      <% if (rs.getString("Description") != null) { %><p><%= esc(rs.getString("Description")) %></p><% } %>

      <% if (sitterUser) { %>
      <details>
        <summary>Edit</summary>
        <form method="post" class="form-grid">
          <input type="hidden" name="action" value="update">
          <input type="hidden" name="id" value="<%= rs.getInt("ServiceID") %>">
          <label>Name <input name="name" maxlength="100" value="<%= esc(rs.getString("ServiceName")) %>" required></label>
          <label>Category <select name="category" required><%= options(SERVICE_CATEGORIES, rs.getString("Category")) %></select></label>
          <label>Price ($) <input name="price" type="number" min="0" step="0.01" value="<%= rs.getBigDecimal("Price") %>" required></label>
          <label>Duration (minutes) <input name="duration" type="number" min="1" value="<%= rs.getInt("DurationMinutes") %>" required></label>
          <label>Capacity <input name="capacity" type="number" min="1" value="<%= rs.getInt("Capacity") %>" required></label>
          <label class="check"><input type="checkbox" name="active" <%= available ? "checked" : "" %>> Available to book</label>
          <label class="wide">Description <textarea name="description" maxlength="255"><%= esc(rs.getString("Description")) %></textarea></label>
          <div class="wide"><button class="btn btn-primary" type="submit">Save</button></div>
        </form>
      </details>
      <% } else { %>
      <div class="card-actions"><a class="btn btn-primary btn-small" href="bookings.jsp?serviceId=<%= rs.getInt("ServiceID") %>#request">Book this</a></div>
      <% } %>
    </article>
<%
            }
        }
    } catch (Exception e) { %><p class="notice notice-error"><%= esc(e.getMessage()) %></p><% }
    if (serviceCount == 0) { %><p class="muted"><%= sitterUser ? "You haven't added any services yet." : "No services are available right now." %></p><% } %>
  </div>
</main>
</div>
</body>
</html>
