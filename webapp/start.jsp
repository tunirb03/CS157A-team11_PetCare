<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    boolean login = "login".equals(request.getParameter("mode"));
    String mode = login ? "login" : "start";
    String action = login ? "Log in here!" : "Get started here!";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <%@ include file="/WEB-INF/jspf/landing-head.jspf" %>
  <title><%= login ? "Log in" : "Get started" %> | PetCare</title>
</head>
<body class="landing">
<%@ include file="/WEB-INF/jspf/sound.jspf" %>

<main class="page">
  <a class="back" href="index.jsp">Back to home</a>
  <h1 class="page-title"><%= login ? "Welcome back!" : "Let's get you set up" %></h1>

  <div class="choices">
    <section class="choice choice-owner">
      <img class="pet pet-dog" src="assets/img/dog.png" alt="A happy cartoon dog sitting next to a tennis ball">
      <h2>Own a pet?</h2>
      <a class="btn btn-primary" href="account.jsp?mode=<%= mode %>&amp;role=owner"><%= action %></a>
    </section>

    <section class="choice choice-sitter">
      <img class="pet pet-cat" src="assets/img/cat.png" alt="A black cartoon cat knocking over a coffee cup">
      <h2>Wanna take care of pets?</h2>
      <a class="btn btn-primary" href="account.jsp?mode=<%= mode %>&amp;role=sitter"><%= action %></a>
    </section>
  </div>
</main>
</body>
</html>
