<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    int ownerId = (Integer) session.getAttribute("userId");
    List<String> tables = new ArrayList<>(); String current = null;
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
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Pet SET PetName=?,Species=?,Breed=?,Age=?,Gender=?,FeedingInstructions=?,MedicationNeeds=?,BehavioralNotes=?,EmergencyNotes=? WHERE PetID=? AND OwnerID=?")) {
                    ps.setString(1, request.getParameter("name")); ps.setString(2, request.getParameter("species"));
                    ps.setString(3, request.getParameter("breed")); ps.setInt(4, intParam(request.getParameter("age"), 0));
                    ps.setString(5, request.getParameter("gender")); ps.setString(6, request.getParameter("feeding"));
                    ps.setString(7, request.getParameter("medication")); ps.setString(8, request.getParameter("behavior"));
                    ps.setString(9, request.getParameter("emergency")); ps.setInt(10, id); ps.setInt(11, ownerId);
                    ps.executeUpdate();
                }
                message = "Pet updated.";
            } else {
                try (PreparedStatement ps = conn.prepareStatement("INSERT INTO Pet(OwnerID,PetName,Species,Breed,Age,Gender,FeedingInstructions,MedicationNeeds,BehavioralNotes,EmergencyNotes) VALUES(?,?,?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, ownerId); ps.setString(2, request.getParameter("name")); ps.setString(3, request.getParameter("species"));
                    ps.setString(4, request.getParameter("breed")); ps.setInt(5, intParam(request.getParameter("age"), 0));
                    ps.setString(6, request.getParameter("gender")); ps.setString(7, request.getParameter("feeding"));
                    ps.setString(8, request.getParameter("medication")); ps.setString(9, request.getParameter("behavior"));
                    ps.setString(10, request.getParameter("emergency")); ps.executeUpdate();
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
<label>Feeding instructions <textarea name="feeding"></textarea></label><label>Medication needs <textarea name="medication"></textarea></label>
<label>Behavioral notes <textarea name="behavior"></textarea></label><label>Emergency notes <textarea name="emergency"></textarea></label>
<button class="btn btn-primary" type="submit">Add pet</button></form></section>
<h2 class="section-title">Saved pets</h2><%
try (Connection conn = openConnection(application); PreparedStatement ps = conn.prepareStatement("SELECT * FROM Pet WHERE OwnerID=? ORDER BY PetName")) {
    ps.setInt(1, ownerId); try (ResultSet rs = ps.executeQuery()) { while (rs.next()) { %>
<section class="ledger" style="padding:1rem;margin-bottom:1rem"><h3><%= esc(rs.getString("PetName")) %></h3><p><%= esc(rs.getString("Species")) %> <%= rs.getString("Breed") == null ? "" : "— " + esc(rs.getString("Breed")) %></p>
<details><summary>Edit profile</summary><form method="post" class="form-grid"><input type="hidden" name="action" value="update"><input type="hidden" name="id" value="<%= rs.getInt("PetID") %>">
<label>Name <input name="name" value="<%= esc(rs.getString("PetName")) %>" required></label><label>Species <input name="species" value="<%= esc(rs.getString("Species")) %>" required></label><label>Breed <input name="breed" value="<%= esc(rs.getString("Breed")) %>"></label><label>Age <input name="age" type="number" value="<%= rs.getInt("Age") %>"></label><label>Gender <input name="gender" value="<%= esc(rs.getString("Gender")) %>"></label>
<label>Feeding <textarea name="feeding"><%= esc(rs.getString("FeedingInstructions")) %></textarea></label><label>Medication <textarea name="medication"><%= esc(rs.getString("MedicationNeeds")) %></textarea></label><label>Behavior <textarea name="behavior"><%= esc(rs.getString("BehavioralNotes")) %></textarea></label><label>Emergency <textarea name="emergency"><%= esc(rs.getString("EmergencyNotes")) %></textarea></label><button class="btn btn-primary">Save changes</button></form></details>
<form method="post" style="margin-top:.75rem"><input type="hidden" name="action" value="delete"><input type="hidden" name="id" value="<%= rs.getInt("PetID") %>"><button class="btn btn-outline" type="submit">Delete</button></form></section>
<% } } } catch (Exception e) { %><p class="notice"><%= esc(e.getMessage()) %></p><% } %>
</main></div></body></html>
