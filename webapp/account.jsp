<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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

      <%-- Login is not checked yet. This form just opens the dashboard for now. --%>
      <form method="post" action="dashboard.jsp">
        <input type="hidden" name="role" value="<%= role %>">
        <% if (!login) { %>
          <label for="name">Full name</label>
          <input id="name" name="name" type="text" autocomplete="name" required>
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
