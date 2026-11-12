<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%!
    private void setPetFields(PreparedStatement ps, int start, jakarta.servlet.http.HttpServletRequest req) throws SQLException {
        ps.setString(start, text(req.getParameter("name")));
        ps.setString(start + 1, text(req.getParameter("species")));
        ps.setString(start + 2, text(req.getParameter("breed")));
        String age = text(req.getParameter("age"));
        if (age == null) ps.setNull(start + 3, Types.INTEGER); else ps.setInt(start + 3, Math.max(0, intParam(age, 0)));
        ps.setString(start + 4, pick(req.getParameter("gender"), PET_GENDERS));
        ps.setString(start + 5, text(req.getParameter("color")));
        ps.setString(start + 6, text(req.getParameter("markings")));
        ps.setString(start + 7, text(req.getParameter("toys")));
        ps.setString(start + 8, text(req.getParameter("emergency")));
        ps.setString(start + 9, text(req.getParameter("photo")));
    }
%>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    if (isSitter(session)) { response.sendRedirect("dashboard.jsp"); return; }
    int ownerId = (Integer) session.getAttribute("userId");
    String message = null, error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        int id = intParam(request.getParameter("id"), 0);
        try (Connection conn = openConnection(application)) {
            if ("delete".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM Pet WHERE PetID=? AND OwnerID=?")) {
                    ps.setInt(1, id); ps.setInt(2, ownerId);
                    message = ps.executeUpdate() == 1 ? "Pet deleted." : "That pet was not found.";
                }
            } else if ("update".equals(action)) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Pet SET PetName=?,Species=?,Breed=?,Age=?,Gender=?,Color=?,Markings=?,FavoriteToys=?,EmergencyNotes=?,PhotoURL=? " +
                        "WHERE PetID=? AND OwnerID=?")) {
                    setPetFields(ps, 1, request);
                    ps.setInt(11, id); ps.setInt(12, ownerId);
                    ps.executeUpdate();
                }
                message = "Pet updated.";
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Pet(OwnerID,PetName,Species,Breed,Age,Gender,Color,Markings,FavoriteToys,EmergencyNotes,PhotoURL) " +
                        "VALUES(?,?,?,?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, ownerId);
                    setPetFields(ps, 2, request);
                    ps.executeUpdate();
                }
                message = "Pet added.";
            }
        } catch (SQLIntegrityConstraintViolationException e) {
            error = "delete".equals(action) ? "This pet has bookings on record, so it can't be deleted." : e.getMessage();
        } catch (Exception e) {
            error = e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>My Pets | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1>My pets</h1>
  <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>

  <section class="panel">
    <h2>Add a pet</h2>
    <form method="post" class="form-grid">
      <input type="hidden" name="action" value="add">
      <label>Name <input name="name" maxlength="50" required></label>
      <label>Species <input name="species" maxlength="30" placeholder="Dog, cat, etc." required></label>
      <label>Breed <input name="breed" maxlength="50"></label>
      <label>Age <input name="age" type="number" min="0"></label>
      <label>Gender <select name="gender"><option value="">Not set</option><%= options(PET_GENDERS, null) %></select></label>
      <label>Color <input name="color" maxlength="50"></label>
      <label>Markings <input name="markings" maxlength="100"></label>
      <label>Favorite toys <input name="toys" maxlength="100"></label>
      <label class="wide">Emergency notes <textarea name="emergency" maxlength="255"></textarea></label>
      <label class="wide">Photo URL <input name="photo" type="url" maxlength="255"></label>
      <div class="wide"><button class="btn btn-primary" type="submit">Add pet</button></div>
    </form>
  </section>

  <h2 class="section-title">Saved pets</h2>
  <div class="cards">
<%
    int petCount = 0;
    try (Connection conn = openConnection(application);
         PreparedStatement ps = conn.prepareStatement("SELECT * FROM Pet WHERE OwnerID=? ORDER BY PetName")) {
        ps.setInt(1, ownerId);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                petCount++;
                int petId = rs.getInt("PetID");
                String age = rs.getString("Age");
%>
    <article class="card">
      <h3><%= esc(rs.getString("PetName")) %></h3>
      <p class="card-meta">
        <%= esc(rs.getString("Species")) %>
        <% if (rs.getString("Breed") != null) { %> · <%= esc(rs.getString("Breed")) %><% } %>
        <% if (age != null) { %> · <%= esc(age) %> yr<% } %>
        <% if (rs.getString("Gender") != null) { %> · <%= esc(rs.getString("Gender")) %><% } %>
      </p>
      <% if (rs.getString("EmergencyNotes") != null) { %><p><strong>Emergency:</strong> <%= esc(rs.getString("EmergencyNotes")) %></p><% } %>
      <details>
        <summary>Edit profile</summary>
        <form method="post" class="form-grid">
          <input type="hidden" name="action" value="update">
          <input type="hidden" name="id" value="<%= petId %>">
          <label>Name <input name="name" maxlength="50" value="<%= esc(rs.getString("PetName")) %>" required></label>
          <label>Species <input name="species" maxlength="30" value="<%= esc(rs.getString("Species")) %>" required></label>
          <label>Breed <input name="breed" maxlength="50" value="<%= esc(rs.getString("Breed")) %>"></label>
          <label>Age <input name="age" type="number" min="0" value="<%= esc(age) %>"></label>
          <label>Gender <select name="gender"><option value="">Not set</option><%= options(PET_GENDERS, rs.getString("Gender")) %></select></label>
          <label>Color <input name="color" maxlength="50" value="<%= esc(rs.getString("Color")) %>"></label>
          <label>Markings <input name="markings" maxlength="100" value="<%= esc(rs.getString("Markings")) %>"></label>
          <label>Favorite toys <input name="toys" maxlength="100" value="<%= esc(rs.getString("FavoriteToys")) %>"></label>
          <label class="wide">Emergency notes <textarea name="emergency" maxlength="255"><%= esc(rs.getString("EmergencyNotes")) %></textarea></label>
          <label class="wide">Photo URL <input name="photo" type="url" maxlength="255" value="<%= esc(rs.getString("PhotoURL")) %>"></label>
          <div class="wide"><button class="btn btn-primary" type="submit">Save changes</button></div>
        </form>
      </details>
      <form method="post" class="card-actions" onsubmit="return confirm('Delete this pet?');">
        <input type="hidden" name="action" value="delete">
        <input type="hidden" name="id" value="<%= petId %>">
        <button class="btn btn-outline btn-small" type="submit">Delete</button>
      </form>
    </article>
<%
            }
        }
    } catch (Exception e) { %><p class="notice notice-error"><%= esc(e.getMessage()) %></p><% }
    if (petCount == 0) { %><p class="muted">No pets yet. Add one above.</p><% } %>
  </div>
</main>
</div>
</body>
</html>
