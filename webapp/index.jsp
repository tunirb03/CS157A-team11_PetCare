<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <%@ include file="/WEB-INF/jspf/landing-head.jspf" %>
  <title>Welcome | PetCare</title>
</head>
<body class="landing">
<%@ include file="/WEB-INF/jspf/sound.jspf" %>

<main class="home">
  <section class="home-copy">
    <h1 class="title">welcome to petcare!</h1>
    <p class="subtitle">Book care for your pet, or run your pet-sitting business, all in one place.</p>
    <div class="actions">
      <a class="btn btn-primary" href="start.jsp?mode=start">Get started</a>
      <a class="btn btn-outline" href="start.jsp?mode=login">Log in</a>
    </div>
  </section>
</main>

<img class="home-girl" src="assets/img/girl.png" alt="" aria-hidden="true">
</body>
</html>
