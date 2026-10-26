<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%!
    // Turns a rating like 4 into four filled stars and one empty star (HTML entities)
    private String stars(int n) {
        int full = Math.max(0, Math.min(5, n));
        StringBuilder b = new StringBuilder();
        for (int i = 0; i < 5; i++) b.append(i < full ? "&#9733;" : "&#9734;");
        return b.toString();
    }
%>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    int userId = (Integer) session.getAttribute("userId");
    boolean sitterUser = isSitter(session);
    String message = null, error = null;

    // Owners can leave one review per completed booking
    if ("POST".equalsIgnoreCase(request.getMethod()) && !sitterUser) {
        int bookingId = intParam(request.getParameter("bookingId"), 0);
        int rating = intParam(request.getParameter("rating"), 0);
        String comment = text(request.getParameter("comment"));
        double tip = doubleParam(request.getParameter("tip"), 0);
        try (Connection c = openConnection(application)) {
            if (rating < 1 || rating > 5) throw new Exception("Please pick a rating from 1 to 5.");
            if (Double.isNaN(tip) || tip < 0 || tip > 999999.99) throw new Exception("The tip must be between $0 and $999,999.99.");
            if (comment != null && comment.length() > 500) throw new Exception("Comments can be at most 500 characters.");
            try (PreparedStatement p = c.prepareStatement("SELECT Status FROM booking WHERE BookingID=? AND ClientID=?")) {
                p.setInt(1, bookingId); p.setInt(2, userId);
                try (ResultSet r = p.executeQuery()) {
                    if (!r.next()) throw new Exception("You can only review your own bookings.");
                    if (!"COMPLETED".equals(r.getString(1))) throw new Exception("You can review a booking after it is completed.");
                }
            }
            try (PreparedStatement p = c.prepareStatement(
                    "INSERT INTO review(BookingID,ClientID,Rating,`Comment`,TipAmount,ReviewDate) VALUES(?,?,?,?,?,CURDATE())")) {
                p.setInt(1, bookingId); p.setInt(2, userId); p.setInt(3, rating);
                p.setString(4, comment); p.setDouble(5, tip);
                p.executeUpdate();
            }
            audit(c, userId, "ADD_REVIEW", "Reviewed booking " + bookingId + ": " + rating + " out of 5");
            message = "Thanks! Your review for booking #" + bookingId + " was saved.";
        } catch (SQLIntegrityConstraintViolationException e) {
            error = "That booking already has a review.";
        } catch (Exception e) { error = e.getMessage(); }
    }

    // Load what the page shows: bookings still waiting for a review (owners) and the reviews themselves
    List<String[]> eligible = new ArrayList<>();
    List<String[]> reviews = new ArrayList<>();
    int reviewCount = 0;
    double ratingSum = 0, tipsTotal = 0;
    String listError = null;
    try (Connection c = openConnection(application)) {
        String servicesSql = "(SELECT GROUP_CONCAT(sv.ServiceName SEPARATOR ', ') FROM booking_service bs " +
                             "JOIN service sv ON sv.ServiceID=bs.ServiceID WHERE bs.BookingID=b.BookingID)";
        if (!sitterUser) {
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT b.BookingID, b.StartDateTime, st.BusinessName, " + servicesSql + " AS Services " +
                    "FROM booking b JOIN sitter st ON st.UserID=b.SitterID " +
                    "WHERE b.ClientID=? AND b.Status='COMPLETED' " +
                    "AND NOT EXISTS (SELECT 1 FROM review rv WHERE rv.BookingID=b.BookingID) " +
                    "ORDER BY b.StartDateTime DESC")) {
                p.setInt(1, userId);
                try (ResultSet r = p.executeQuery()) {
                    while (r.next()) eligible.add(new String[]{
                        String.valueOf(r.getInt("BookingID")), r.getString("Services"),
                        r.getString("BusinessName"), r.getString("StartDateTime") });
                }
            }
        }
        try (PreparedStatement p = c.prepareStatement(
                "SELECT rv.BookingID, rv.Rating, rv.`Comment`, rv.TipAmount, rv.ReviewDate, " +
                (sitterUser ? "cu.FullName" : "st.BusinessName") + " AS Other, " + servicesSql + " AS Services " +
                "FROM review rv JOIN booking b ON b.BookingID=rv.BookingID " +
                "JOIN `user` cu ON cu.UserID=b.ClientID JOIN sitter st ON st.UserID=b.SitterID " +
                "WHERE b." + (sitterUser ? "SitterID" : "ClientID") + "=? ORDER BY rv.ReviewID DESC")) {
            p.setInt(1, userId);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) {
                    reviewCount++;
                    ratingSum += r.getInt("Rating");
                    tipsTotal += r.getDouble("TipAmount");
                    reviews.add(new String[]{
                        String.valueOf(r.getInt("BookingID")), String.valueOf(r.getInt("Rating")),
                        r.getString("Comment"), String.format("%.2f", r.getDouble("TipAmount")),
                        r.getString("ReviewDate"), r.getString("Other"), r.getString("Services") });
                }
            }
        }
    } catch (Exception e) { listError = e.getMessage(); }
    double avgRating = reviewCount == 0 ? 0 : ratingSum / reviewCount;
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Reviews | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1><%= sitterUser ? "Reviews from my clients" : "My reviews" %></h1>
  <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>
  <% if (listError != null) { %><p class="notice notice-error"><%= esc(listError) %></p><% } %>

<% if (sitterUser) { %>
  <section class="panel">
    <h2>Rating summary</h2>
    <% if (reviewCount == 0) { %>
      <p class="muted">No reviews yet. Clients can review a booking after you mark it completed.</p>
    <% } else { %>
      <p class="card-meta">
        <%= stars((int) Math.round(avgRating)) %>
        <strong><%= String.format("%.1f", avgRating) %></strong> out of 5
        · <%= reviewCount %> review<%= reviewCount == 1 ? "" : "s" %>
        · Tips received: <strong>$<%= String.format("%.2f", tipsTotal) %></strong>
      </p>
    <% } %>
  </section>
<% } else { %>
  <section class="panel">
    <h2>Leave a review</h2>
    <% if (eligible.isEmpty()) { %>
      <p class="muted">No completed bookings are waiting for a review.</p>
    <% } else { %>
    <form method="post" class="form-grid">
      <label class="wide">Completed booking
        <select name="bookingId" required>
          <option value="">Choose a booking</option>
          <% for (String[] opt : eligible) { %>
          <option value="<%= esc(opt[0]) %>">#<%= esc(opt[0]) %> · <%= esc(opt[1]) %> · <%= esc(opt[2]) %> · <%= dt(opt[3]) %></option>
          <% } %>
        </select>
      </label>
      <label>Rating
        <select name="rating" required>
          <option value="">Choose a rating</option>
          <option value="5">5 - Excellent</option>
          <option value="4">4 - Good</option>
          <option value="3">3 - Okay</option>
          <option value="2">2 - Poor</option>
          <option value="1">1 - Terrible</option>
        </select>
      </label>
      <label>Tip ($, optional) <input name="tip" type="number" min="0" step="0.01" value="0"></label>
      <label class="wide">Comment (optional)
        <textarea name="comment" rows="3" maxlength="500"></textarea>
      </label>
      <div class="wide"><button class="btn btn-primary" type="submit">Submit review</button></div>
    </form>
    <% } %>
  </section>
<% } %>

  <h2 class="section-title"><%= sitterUser ? "Reviews received" : "Reviews I wrote" %></h2>
  <div class="cards">
    <% for (String[] rv : reviews) { %>
    <article class="card">
      <h3>Booking #<%= esc(rv[0]) %> · <%= esc(rv[6]) %> <span class="chip chip-completed"><%= stars(Integer.parseInt(rv[1])) %></span></h3>
      <p class="card-meta"><%= sitterUser ? "From " : "For " %><%= esc(rv[5]) %> · <%= esc(rv[4]) %> · Tip: $<%= rv[3] %></p>
      <% if (rv[2] != null) { %><p><%= esc(rv[2]) %></p><% } %>
    </article>
    <% } %>
    <% if (reviews.isEmpty()) { %><p class="muted">No reviews yet.</p><% } %>
  </div>
</main>
</div>
</body>
</html>
