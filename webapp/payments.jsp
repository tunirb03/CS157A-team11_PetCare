<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    int userId = (Integer) session.getAttribute("userId");   // always from the session, never from the URL
    boolean sitterUser = isSitter(session);
    String message = null, error = null;
    // Owners see their own bookings (ClientID). Sitters see bookings assigned to them (SitterID).
    String ownColumn = sitterUser ? "SitterID" : "ClientID";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        int bookingId = intParam(request.getParameter("bookingId"), 0);
        String method = pick(request.getParameter("method"), PAYMENT_METHODS);
        String status = pick(request.getParameter("status"), PAYMENT_STATUSES);
        double amount = doubleParam(request.getParameter("amount"), -1);
        try (Connection c = openConnection(application)) {
            if (method == null || status == null || amount < 0) throw new Exception("Please pick a booking, a method, a status, and an amount of 0 or more.");
            try (PreparedStatement p = c.prepareStatement("SELECT 1 FROM Booking WHERE BookingID=? AND " + ownColumn + "=?")) {
                p.setInt(1, bookingId); p.setInt(2, userId);
                try (ResultSet r = p.executeQuery()) { if (!r.next()) throw new Exception("You can only record payments for your own bookings."); }
            }
            // Payment.BookingID is UNIQUE (0 or 1 payment per booking), so saving again updates the same row.
            // PaymentTime stays empty while the payment is pending.
            try (PreparedStatement p = c.prepareStatement(
                    "INSERT INTO Payment(BookingID,Amount,PaymentMethod,PaymentStatus,PaymentTime) VALUES(?,?,?,?,IF(?='PENDING',NULL,NOW())) " +
                    "ON DUPLICATE KEY UPDATE Amount=VALUES(Amount), PaymentMethod=VALUES(PaymentMethod), " +
                    "PaymentStatus=VALUES(PaymentStatus), PaymentTime=VALUES(PaymentTime)")) {
                p.setInt(1, bookingId); p.setDouble(2, amount); p.setString(3, method); p.setString(4, status); p.setString(5, status);
                p.executeUpdate();
            }
            audit(c, userId, "RECORD_PAYMENT", "Booking " + bookingId + ": " + method + " $" + String.format("%.2f", amount) + " " + status);
            message = "Payment for booking #" + bookingId + " saved.";
        } catch (Exception e) { error = e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Payments | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1><%= sitterUser ? "Payments" : "My payments" %></h1>
  <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>

  <section class="panel">
    <h2>Record or update a payment</h2>
    <form method="post" class="form-grid">
      <label class="wide">Booking
        <select name="bookingId" required>
          <option value="">Choose a booking</option>
<%
    try (Connection c = openConnection(application);
         PreparedStatement p = c.prepareStatement(
            "SELECT b.BookingID, b.StartDateTime, " +
            "(SELECT GROUP_CONCAT(sv.ServiceName SEPARATOR ', ') FROM BookingService bs JOIN Service sv ON sv.ServiceID=bs.ServiceID WHERE bs.BookingID=b.BookingID) AS Services, " +
            "(SELECT pm.PaymentStatus FROM Payment pm WHERE pm.BookingID=b.BookingID) AS PaymentStatus " +
            "FROM Booking b WHERE b." + ownColumn + "=? ORDER BY b.StartDateTime DESC")) {
        p.setInt(1, userId);
        try (ResultSet r = p.executeQuery()) {
            while (r.next()) { %>
          <option value="<%= r.getInt("BookingID") %>">#<%= r.getInt("BookingID") %> · <%= esc(r.getString("Services")) %> · <%= dt(r.getString("StartDateTime")) %><%= r.getString("PaymentStatus") == null ? "" : " (currently " + label(r.getString("PaymentStatus")).toLowerCase() + ")" %></option>
<%          }
        }
    } catch (Exception e) { %><option value="">Could not load bookings</option><% } %>
        </select>
      </label>
      <label>Amount ($) <input name="amount" type="number" min="0" step="0.01" required></label>
      <label>Method <select name="method"><%= options(PAYMENT_METHODS, null) %></select></label>
      <label>Status <select name="status"><%= options(PAYMENT_STATUSES, null) %></select></label>
      <div class="wide"><button class="btn btn-primary" type="submit">Save payment</button></div>
    </form>
  </section>

  <h2 class="section-title">Payment history</h2>
  <div class="cards">
<%
    int payCount = 0;
    try (Connection c = openConnection(application);
         PreparedStatement p = c.prepareStatement(
            "SELECT pm.*, cu.FullName AS ClientName, st.BusinessName, " +
            "(SELECT GROUP_CONCAT(sv.ServiceName SEPARATOR ', ') FROM BookingService bs JOIN Service sv ON sv.ServiceID=bs.ServiceID WHERE bs.BookingID=b.BookingID) AS Services " +
            "FROM Payment pm JOIN Booking b ON b.BookingID=pm.BookingID " +
            "JOIN `User` cu ON cu.UserID=b.ClientID JOIN Sitter st ON st.UserID=b.SitterID " +
            "WHERE b." + ownColumn + "=? ORDER BY pm.PaymentID DESC")) {
        p.setInt(1, userId);
        try (ResultSet r = p.executeQuery()) {
            while (r.next()) {
                payCount++;
                String chip = chipClass(r.getString("PaymentStatus"));
%>
    <article class="card">
      <h3>Booking #<%= r.getInt("BookingID") %> · <%= esc(r.getString("Services")) %> <span class="chip <%= chip == null ? "" : chip %>"><%= esc(label(r.getString("PaymentStatus"))) %></span></h3>
      <p class="card-meta">
        $<%= String.format("%.2f", r.getDouble("Amount")) %> · <%= esc(label(r.getString("PaymentMethod"))) %>
        · <%= sitterUser ? "from " + esc(r.getString("ClientName")) : "to " + esc(r.getString("BusinessName")) %>
      </p>
      <p><%= r.getString("PaymentTime") == null ? "Not paid yet" : esc(label(r.getString("PaymentStatus"))) + " " + dt(r.getString("PaymentTime")) %></p>
    </article>
<%
            }
        }
    } catch (Exception e) { %><p class="notice notice-error"><%= esc(e.getMessage()) %></p><% }
    if (payCount == 0) { %><p class="muted">No payments recorded yet.</p><% } %>
  </div>
</main>
</div>
</body>
</html>
