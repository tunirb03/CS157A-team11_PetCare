<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    boolean sitterUser = isSitter(session); String message = null, error = null;
    try (Connection conn = openConnection(application)) {
        if ("POST".equalsIgnoreCase(request.getMethod()) && sitterUser) {
            String action = request.getParameter("action"); int id = intParam(request.getParameter("id"), 0);
            if ("add".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement("INSERT INTO Service(SitterID,ServiceName,Category,Description,Price,Duration,Capacity) VALUES(?,?,?,?,?,?,?)")) {
                    ps.setInt(1, (Integer)session.getAttribute("userId")); ps.setString(2, request.getParameter("name")); ps.setString(3, request.getParameter("category")); ps.setString(4, request.getParameter("description")); ps.setDouble(5, doubleParam(request.getParameter("price"), 0)); ps.setInt(6, intParam(request.getParameter("duration"), 30)); ps.setInt(7, intParam(request.getParameter("capacity"), 1)); ps.executeUpdate();
                } message = "Service added.";
            } else if ("update".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Service SET ServiceName=?,Category=?,Price=?,Duration=?,Capacity=?,AvailabilityStatus=? WHERE ServiceID=? AND SitterID=?")) {
                    ps.setString(1, request.getParameter("name")); ps.setString(2, request.getParameter("category")); ps.setDouble(3, doubleParam(request.getParameter("price"), 0)); ps.setInt(4, intParam(request.getParameter("duration"), 30)); ps.setInt(5, intParam(request.getParameter("capacity"), 1)); ps.setString(6, request.getParameter("active") != null ? "AVAILABLE" : "UNAVAILABLE"); ps.setInt(7, id); ps.setInt(8, (Integer)session.getAttribute("userId")); ps.executeUpdate();
                } message = "Service updated.";
            }
        }
    } catch (Exception e) { error = e.getMessage(); }
%>
<!DOCTYPE html><html lang="en"><head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Services | PetCare</title></head>
<body><%@ include file="/WEB-INF/jspf/sound.jspf" %><div class="shell"><%@ include file="/WEB-INF/jspf/sidebar.jspf" %><main class="main"><p class="crumb"><a href="dashboard.jsp">Dashboard</a></p><h1><%= sitterUser ? "Manage my services" : "Browse services" %></h1>
<% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %><% if (error != null) { %><p class="notice"><%= esc(error) %></p><% } %>
<% if (sitterUser) { %><section class="panel"><h2>Add service</h2><form method="post" class="form-grid"><input type="hidden" name="action" value="add"><label>Name <input name="name" required></label><label>Category <input name="category" required></label><label>Description <textarea name="description"></textarea></label><label>Price <input name="price" type="number" min="0" step="0.01" required></label><label>Duration (minutes) <input name="duration" type="number" min="1" value="30" required></label><label>Capacity <input name="capacity" type="number" min="1" value="1" required></label><button class="btn btn-primary">Add service</button></form></section><% } %>
<h2 class="section-title"><%= sitterUser ? "My services" : "Available services" %></h2><div class="ledger"><%
String serviceSql = sitterUser ? "SELECT * FROM Service WHERE SitterID=? ORDER BY ServiceName" : "SELECT * FROM Service WHERE AvailabilityStatus='AVAILABLE' ORDER BY ServiceName";
try (Connection conn = openConnection(application); PreparedStatement ps = conn.prepareStatement(serviceSql)) { if (sitterUser) ps.setInt(1, (Integer)session.getAttribute("userId")); try (ResultSet rs = ps.executeQuery()) { while (rs.next()) { %>
<article style="padding:1rem;border-bottom:1px solid #ddd"><h3><%= esc(rs.getString("ServiceName")) %></h3><p><%= esc(rs.getString("Category")) %> · $<%= String.format("%.2f", rs.getDouble("Price")) %> · <%= rs.getInt("Duration") %> minutes · capacity <%= rs.getInt("Capacity") %></p><% if (rs.getString("Description") != null) { %><p><%= esc(rs.getString("Description")) %></p><% } %>
<% if (sitterUser) { %><details><summary>Edit</summary><form method="post" class="form-grid"><input type="hidden" name="action" value="update"><input type="hidden" name="id" value="<%= rs.getInt("ServiceID") %>"><label>Name <input name="name" value="<%= esc(rs.getString("ServiceName")) %>" required></label><label>Category <input name="category" value="<%= esc(rs.getString("Category")) %>" required></label><label>Price <input name="price" type="number" step="0.01" value="<%= rs.getDouble("Price") %>" required></label><label>Duration <input name="duration" type="number" value="<%= rs.getInt("Duration") %>" required></label><label>Capacity <input name="capacity" type="number" value="<%= rs.getInt("Capacity") %>" required></label><label><input type="checkbox" name="active" <%= "AVAILABLE".equals(rs.getString("AvailabilityStatus")) ? "checked" : "" %>> Active</label><button class="btn btn-primary">Save</button></form></details><% } %></article>
<% } } } catch (Exception e) { %><p class="notice"><%= esc(e.getMessage()) %></p><% } %>
</div></main></div></body></html>
