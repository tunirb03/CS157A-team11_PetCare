<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    if (isSitter(session)) { response.sendRedirect("dashboard.jsp"); return; }
    int ownerId = (Integer) session.getAttribute("userId");
    String message = null, error = null;
    try (Connection conn = openConnection(application)) {
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String action = request.getParameter("action");
            int id = intParam(request.getParameter("id"), 0);
            if ("delete".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM Pet WHERE PetID=? AND OwnerID=?")) {
                    ps.setInt(1, id); ps.setInt(2, ownerId); ps.executeUpdate();
                }
                message = "Pet deleted.";
            } else if ("update".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Pet SET PetName=?,Species=?,Breed=?,Age=?,Gender=?,Color=?,Markings=?,FavoriteToys=?,EmergencyNotes=?,PhotoURL=? WHERE PetID=? AND OwnerID=?")) {
                    ps.setString(1, request.getParameter("name")); ps.setString(2, request.getParameter("species"));
                    ps.setString(3, request.getParameter("breed")); ps.setInt(4, intParam(request.getParameter("age"), 0));
                    ps.setString(5, request.getParameter("gender")); ps.setString(6, request.getParameter("color"));
                    ps.setString(7, request.getParameter("markings")); ps.setString(8, request.getParameter("toys"));
                    ps.setString(9, request.getParameter("emergency")); ps.setString(10, request.getParameter("photo")); ps.setInt(11, id); ps.setInt(12, ownerId);
                    ps.executeUpdate();
                }
                message = "Pet updated.";
            } else {
                try (PreparedStatement ps = conn.prepareStatement("INSERT INTO Pet(OwnerID,PetName,Species,Breed,Age,Gender,Color,Markings,FavoriteToys,EmergencyNotes,PhotoURL) VALUES(?,?,?,?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, ownerId); ps.setString(2, request.getParameter("name")); ps.setString(3, request.getParameter("species"));
                    ps.setString(4, request.getParameter("breed")); ps.setInt(5, intParam(request.getParameter("age"), 0));
                    ps.setString(6, request.getParameter("gender")); ps.setString(7, request.getParameter("color"));
                    ps.setString(8, request.getParameter("markings")); ps.setString(9, request.getParameter("toys"));
                    ps.setString(10, request.getParameter("emergency")); ps.setString(11, request.getParameter("photo")); ps.executeUpdate();
                }
                message = "Pet added.";
            }
        }
    } catch (Exception e) { error = e.getMessage(); }
%>
<!DOCTYPE html><html lang="en"><head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>My Pets | PetCare</title></head>
<body><%@ include file="/WEB-INF/jspf/sound.jspf" %><div class="shell"><%@ include file="/WEB-INF/jspf/sidebar.jspf" %><main class="main">
<p class="crumb"><a href="dashboard.jsp">Dashboard</a></p><h1>My pets</h1>
<% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %><% if (error != null) { %><p class="notice"><%= esc(error) %></p><% } %>
<section class="panel"><h2>Add a pet</h2><form method="post" class="form-grid">
<label>Name <input name="name" required></label><label>Species <input name="species" placeholder="Dog, cat, etc." required></label>
<label>Breed <input name="breed"></label><label>Age <input name="age" type="number" min="0"></label><label>Gender <input name="gender"></label>
<label>Color <input name="color"></label><label>Markings <input name="markings"></label><label>Favorite toys <input name="toys"></label>
<label>Emergency notes <textarea name="emergency"></textarea></label><label>Photo URL <input name="photo"></label>
<button class="btn btn-primary" type="submit">Add pet</button></form></section>
<h2 class="section-title">Saved pets</h2><%
try (Connection conn = openConnection(application); PreparedStatement ps = conn.prepareStatement("SELECT * FROM Pet WHERE OwnerID=? ORDER BY PetName")) {
    ps.setInt(1, ownerId); try (ResultSet rs = ps.executeQuery()) { while (rs.next()) { %>
<section class="ledger" style="padding:1rem;margin-bottom:1rem"><h3><%= esc(rs.getString("PetName")) %></h3><p><%= esc(rs.getString("Species")) %> <%= rs.getString("Breed") == null ? "" : "— " + esc(rs.getString("Breed")) %></p>
<details><summary>Edit profile</summary><form method="post" class="form-grid"><input type="hidden" name="action" value="update"><input type="hidden" name="id" value="<%= rs.getInt("PetID") %>">
<label>Name <input name="name" value="<%= esc(rs.getString("PetName")) %>" required></label><label>Species <input name="species" value="<%= esc(rs.getString("Species")) %>" required></label><label>Breed <input name="breed" value="<%= esc(rs.getString("Breed")) %>"></label><label>Age <input name="age" type="number" value="<%= rs.getInt("Age") %>"></label><label>Gender <input name="gender" value="<%= esc(rs.getString("Gender")) %>"></label>
<label>Color <input name="color" value="<%= esc(rs.getString("Color")) %>"></label><label>Markings <input name="markings" value="<%= esc(rs.getString("Markings")) %>"></label><label>Favorite toys <input name="toys" value="<%= esc(rs.getString("FavoriteToys")) %>"></label><label>Emergency <textarea name="emergency"><%= esc(rs.getString("EmergencyNotes")) %></textarea></label><label>Photo URL <input name="photo" value="<%= esc(rs.getString("PhotoURL")) %>"></label><button class="btn btn-primary">Save changes</button></form></details>
<form method="post" style="margin-top:.75rem"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="<%= rs.getInt("PetID") %>"><button class="btn btn-outline" type="submit">Delete</button></form></section>
<% } } } catch (Exception e) { %><p class="notice"><%= esc(e.getMessage()) %></p><% } %>
</main></div></body></html>
