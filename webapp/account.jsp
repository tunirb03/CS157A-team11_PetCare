<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    String role = request.getParameter("role");
    if (!"owner".equals(role) && !"sitter".equals(role)) {
        response.sendRedirect("start.jsp");
        return;
    }
    boolean login = "login".equals(request.getParameter("mode"));
    boolean sitter = "sitter".equals(role);

    String heading = login
        ? (sitter ? "Log in as a pet sitter" : "Log in as a pet owner")
        : (sitter ? "Create your pet sitter account" : "Create your pet owner account");
    String button = login ? "Log in" : "Create account";
    String message = null;
    String error = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String name = request.getParameter("name");
        try (Connection conn = openConnection(application)) {
            if (login) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT u.UserID, u.FullName, u.PasswordHash, u.AccountStatus, " +
                        "CASE WHEN EXISTS (SELECT 1 FROM Sitter s WHERE s.UserID=u.UserID) THEN 'sitter' ELSE 'client' END role " +
                        "FROM `User` u WHERE u.Email=?")) {
                    ps.setString(1, email);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next() || !"ACTIVE".equals(rs.getString("AccountStatus")) || !verifyPassword(password, rs.getString("PasswordHash"))) {
                            error = "The email or password is incorrect.";
                        } else {
                            session.setAttribute("userId", rs.getInt("UserID"));
                            session.setAttribute("userName", rs.getString("FullName"));
                            session.setAttribute("role", rs.getString("role"));
                            response.sendRedirect("dashboard.jsp");
                            return;
                        }
                    }
                }
            } else {
                conn.setAutoCommit(false);
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO `User`(FullName,Email,Phone,PasswordHash) VALUES(?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, name);
                    ps.setString(2, email);
                    ps.setString(3, request.getParameter("phone"));
                    ps.setString(4, hashPassword(password));
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        keys.next();
                        int newUserId = keys.getInt(1);
                        if (sitter) {
                            try (PreparedStatement sub = conn.prepareStatement("INSERT INTO Sitter(UserID,BusinessName) VALUES(?,?)")) {
                                sub.setInt(1, newUserId); sub.setString(2, name + " Pet Care"); sub.executeUpdate();
                            }
                        } else {
                            try (PreparedStatement sub = conn.prepareStatement("INSERT INTO Client(UserID) VALUES(?)")) {
                                sub.setInt(1, newUserId); sub.executeUpdate();
                            }
                        }
                    }
                    conn.commit(); conn.setAutoCommit(true);
                    message = "Your account was created. You can now log in.";
                }
            }
        } catch (SQLIntegrityConstraintViolationException e) {
            error = "That email address is already registered.";
        } catch (Exception e) {
            error = hintFor(e) + " (" + e.getMessage() + ")";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <%@ include file="/WEB-INF/jspf/landing-head.jspf" %>
  <title><%= heading %> | PetCare</title>
</head>
<body class="landing">
<%@ include file="/WEB-INF/jspf/sound.jspf" %>

<main class="page">
  <a class="back" href="start.jsp?mode=<%= login ? "login" : "start" %>">Back</a>

  <div class="account">
    <img class="pet pet-snake" src="assets/img/snake.jpg" alt="A pale snake with drawn-on hands, looking happy">

    <section class="panel">
      <h1 class="page-title"><%= heading %></h1>

      <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
      <% if (error != null) { %><p class="notice"><%= esc(error) %></p><% } %>
      <form method="post" action="account.jsp?mode=<%= login ? "login" : "start" %>&amp;role=<%= role %>">
        <input type="hidden" name="role" value="<%= role %>">
        <% if (!login) { %>
          <label for="name">Full name</label>
          <input id="name" name="name" type="text" autocomplete="name" required>
          <label for="phone">Phone number</label>
          <input id="phone" name="phone" type="tel" autocomplete="tel">
        <% } %>
        <label for="email">Email</label>
        <input id="email" name="email" type="email" autocomplete="email" required>

        <label for="password">Password</label>
        <input id="password" name="password" type="password"
               autocomplete="<%= login ? "current-password" : "new-password" %>" required>

        <button class="btn btn-primary btn-block" type="submit"><%= button %></button>
      </form>

      <p class="switch">
        <% if (login) { %>
          New here? <a href="account.jsp?mode=start&amp;role=<%= role %>">Create an account</a>
        <% } else { %>
          Already have an account? <a href="account.jsp?mode=login&amp;role=<%= role %>">Log in</a>
        <% } %>
      </p>
    </section>
  </div>
</main>
</body>
</html>
