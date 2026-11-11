<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%!
    // Fills in the ? placeholders of a query from the list, starting at position "from".
    // Returns the next free position.
    private int bind(PreparedStatement p, List<Object> params, int from) throws SQLException {
        int i = from;
        for (Object o : params) p.setObject(i++, o);
        return i;
    }

    private String money(double v) { return String.format("%,.2f", v); }
%>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    if (!isSitter(session)) { response.sendRedirect("dashboard.jsp"); return; }
    int userId = (Integer) session.getAttribute("userId");
    String error = null;

    // Filters. All of them are optional.
    String fromText = text(request.getParameter("from")), toText = text(request.getParameter("to"));
    String category = pick(request.getParameter("category"), SERVICE_CATEGORIES);
    String status = pick(request.getParameter("status"), BOOKING_STATUSES);
    java.time.LocalDate fromDate = null, toDate = null;
    try {
        if (fromText != null) fromDate = java.time.LocalDate.parse(fromText);
        if (toText != null) toDate = java.time.LocalDate.parse(toText);
        if (fromDate != null && toDate != null && toDate.isBefore(fromDate)) error = "The end date must be on or after the start date.";
    } catch (Exception e) { error = "Please enter dates like 2026-08-01."; }

    // Build the WHERE part once and reuse it in every report query
    StringBuilder where = new StringBuilder(" WHERE b.SitterID=?");
    List<Object> params = new ArrayList<>();
    params.add(userId);
    if (fromDate != null) { where.append(" AND b.StartDateTime >= ?"); params.add(fromDate.atStartOfDay()); }
    if (toDate != null) { where.append(" AND b.StartDateTime < ?"); params.add(toDate.plusDays(1).atStartOfDay()); }
    if (status != null) { where.append(" AND b.Status=?"); params.add(status); }
    if (category != null) {
        where.append(" AND EXISTS (SELECT 1 FROM booking_service bsx JOIN service svx ON svx.ServiceID=bsx.ServiceID " +
                     "WHERE bsx.BookingID=b.BookingID AND svx.Category=?)");
        params.add(category);
    }
    String w = where.toString();

    int bookingCount = 0;
    double revenue = 0, pending = 0, refunded = 0;
    List<String[]> byStatus = new ArrayList<>(), topServices = new ArrayList<>();
    List<String[]> payments = new ArrayList<>(), bookingRows = new ArrayList<>();
    String listError = null;

    if (error == null) {
        try (Connection c = openConnection(application)) {
            // 1) Totals: number of bookings, and money by payment status
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT COUNT(*), " +
                    "COALESCE(SUM(CASE WHEN pm.PaymentStatus='PAID' THEN pm.Amount END),0), " +
                    "COALESCE(SUM(CASE WHEN pm.PaymentStatus='PENDING' THEN pm.Amount END),0), " +
                    "COALESCE(SUM(CASE WHEN pm.PaymentStatus='REFUNDED' THEN pm.Amount END),0) " +
                    "FROM booking b LEFT JOIN payment pm ON pm.BookingID=b.BookingID" + w)) {
                bind(p, params, 1);
                try (ResultSet r = p.executeQuery()) {
                    if (r.next()) { bookingCount = r.getInt(1); revenue = r.getDouble(2); pending = r.getDouble(3); refunded = r.getDouble(4); }
                }
            }
            // 2) Bookings by status
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT b.Status, COUNT(*) FROM booking b" + w + " GROUP BY b.Status ORDER BY COUNT(*) DESC")) {
                bind(p, params, 1);
                try (ResultSet r = p.executeQuery()) {
                    while (r.next()) byStatus.add(new String[]{ r.getString(1), String.valueOf(r.getInt(2)) });
                }
            }
            // 3) Most-booked services (cancelled and declined bookings are not counted)
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT sv.ServiceName, sv.Category, COUNT(*) AS Times, SUM(bs.PriceAtBooking) AS Billed " +
                    "FROM booking b JOIN booking_service bs ON bs.BookingID=b.BookingID " +
                    "JOIN service sv ON sv.ServiceID=bs.ServiceID" + w +
                    " AND b.Status NOT IN ('CANCELLED','DECLINED')" + (category != null ? " AND sv.Category=?" : "") +
                    " GROUP BY sv.ServiceID, sv.ServiceName, sv.Category ORDER BY Times DESC, Billed DESC LIMIT 5")) {
                int next = bind(p, params, 1);
                if (category != null) p.setString(next, category);
                try (ResultSet r = p.executeQuery()) {
                    while (r.next()) topServices.add(new String[]{
                        r.getString(1), r.getString(2), String.valueOf(r.getInt(3)), money(r.getDouble(4)) });
                }
            }
            // 4) Payment history
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT pm.PaymentID, pm.BookingID, cu.FullName, pm.PaymentMethod, pm.PaymentStatus, pm.Amount, pm.PaymentTime " +
                    "FROM payment pm JOIN booking b ON b.BookingID=pm.BookingID " +
                    "JOIN `user` cu ON cu.UserID=b.ClientID" + w + " ORDER BY pm.PaymentID DESC LIMIT 50")) {
                bind(p, params, 1);
                try (ResultSet r = p.executeQuery()) {
                    while (r.next()) payments.add(new String[]{
                        String.valueOf(r.getInt(1)), String.valueOf(r.getInt(2)), r.getString(3), r.getString(4),
                        r.getString(5), money(r.getDouble(6)), r.getString(7) });
                }
            }
            // 5) Booking history
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT b.BookingID, b.StartDateTime, cu.FullName, " +
                    "(SELECT GROUP_CONCAT(sv.ServiceName SEPARATOR ', ') FROM booking_service bs " +
                    "JOIN service sv ON sv.ServiceID=bs.ServiceID WHERE bs.BookingID=b.BookingID) AS Services, " +
                    "b.Status, (SELECT SUM(bs2.PriceAtBooking) FROM booking_service bs2 WHERE bs2.BookingID=b.BookingID) AS Total, " +
                    "pm.PaymentStatus " +
                    "FROM booking b JOIN `user` cu ON cu.UserID=b.ClientID " +
                    "LEFT JOIN payment pm ON pm.BookingID=b.BookingID" + w + " ORDER BY b.StartDateTime DESC LIMIT 50")) {
                bind(p, params, 1);
                try (ResultSet r = p.executeQuery()) {
                    while (r.next()) bookingRows.add(new String[]{
                        String.valueOf(r.getInt(1)), r.getString(2), r.getString(3), r.getString(4),
                        r.getString(5), money(r.getDouble(6)), r.getString(7) });
                }
            }
        } catch (Exception e) { listError = e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Reports | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1>Business reports</h1>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>
  <% if (listError != null) { %><p class="notice notice-error"><%= esc(listError) %></p><% } %>

  <section class="panel">
    <h2>Filters</h2>
    <form method="get" class="form-grid">
      <label>From date <input type="date" name="from" value="<%= esc(fromText) %>"></label>
      <label>To date <input type="date" name="to" value="<%= esc(toText) %>"></label>
      <label>Service category
        <select name="category"><option value="">All categories</option><%= options(SERVICE_CATEGORIES, category) %></select>
      </label>
      <label>Booking status
        <select name="status"><option value="">All statuses</option><%= options(BOOKING_STATUSES, status) %></select>
      </label>
      <div class="wide">
        <button class="btn btn-primary" type="submit">Run report</button>
        <a class="btn btn-outline" href="reports.jsp">Clear filters</a>
      </div>
      <div class="wide"><p class="hint">Dates use each booking's start time. Leave everything blank to include all bookings.</p></div>
    </form>
  </section>

<% if (error == null && listError == null) { %>
  <h2 class="section-title">Summary</h2>
  <div class="cards">
    <article class="card"><h3>Total revenue</h3><p><strong>$<%= money(revenue) %></strong></p><p class="card-meta">Payments marked paid</p></article>
    <article class="card"><h3>Bookings</h3><p><strong><%= bookingCount %></strong></p><p class="card-meta">Matching the filters</p></article>
    <article class="card"><h3>Pending</h3><p><strong>$<%= money(pending) %></strong></p><p class="card-meta">Payments not yet paid</p></article>
    <article class="card"><h3>Refunded</h3><p><strong>$<%= money(refunded) %></strong></p><p class="card-meta">Payments refunded</p></article>
  </div>

  <h2 class="section-title">Bookings by status</h2>
  <% if (byStatus.isEmpty()) { %><p class="muted">No bookings match these filters.</p><% } else { %>
  <div class="data-wrap" tabindex="0" aria-label="Bookings by status">
    <table class="data">
      <thead><tr><th scope="col">Status</th><th scope="col">Bookings</th></tr></thead>
      <tbody>
        <% for (String[] r : byStatus) { String chip = chipClass(r[0]); %>
        <tr><td><span class="chip <%= chip == null ? "" : chip %>"><%= esc(label(r[0])) %></span></td><td><%= esc(r[1]) %></td></tr>
        <% } %>
      </tbody>
    </table>
  </div>
  <% } %>

  <h2 class="section-title">Most-booked services</h2>
  <p class="hint">Cancelled and declined bookings are not counted here.</p>
  <% if (topServices.isEmpty()) { %><p class="muted">No services to show for these filters.</p><% } else { %>
  <div class="data-wrap" tabindex="0" aria-label="Most-booked services">
    <table class="data">
      <thead><tr><th scope="col">Service</th><th scope="col">Category</th><th scope="col">Times booked</th><th scope="col">Billed ($)</th></tr></thead>
      <tbody>
        <% for (String[] r : topServices) { %>
        <tr><td><%= esc(r[0]) %></td><td><%= esc(label(r[1])) %></td><td><%= esc(r[2]) %></td><td><%= esc(r[3]) %></td></tr>
        <% } %>
      </tbody>
    </table>
  </div>
  <% } %>

  <h2 class="section-title">Payment history</h2>
  <% if (payments.isEmpty()) { %><p class="muted">No payments match these filters.</p><% } else { %>
  <div class="data-wrap" tabindex="0" aria-label="Payment history">
    <table class="data">
      <thead><tr><th scope="col">Booking</th><th scope="col">Client</th><th scope="col">Method</th><th scope="col">Status</th><th scope="col">Amount ($)</th><th scope="col">Paid on</th></tr></thead>
      <tbody>
        <% for (String[] r : payments) { String chip = chipClass(r[4]); %>
        <tr>
          <td>#<%= esc(r[1]) %></td><td><%= esc(r[2]) %></td><td><%= esc(label(r[3])) %></td>
          <td><span class="chip <%= chip == null ? "" : chip %>"><%= esc(label(r[4])) %></span></td>
          <td><%= esc(r[5]) %></td><td><%= r[6] == null ? "-" : dt(r[6]) %></td>
        </tr>
        <% } %>
      </tbody>
    </table>
  </div>
  <p class="hint">Showing up to 50 of the newest payments.</p>
  <% } %>

  <h2 class="section-title">Booking history</h2>
  <% if (bookingRows.isEmpty()) { %><p class="muted">No bookings match these filters.</p><% } else { %>
  <div class="data-wrap" tabindex="0" aria-label="Booking history">
    <table class="data">
      <thead><tr><th scope="col">Booking</th><th scope="col">Starts</th><th scope="col">Client</th><th scope="col">Services</th><th scope="col">Status</th><th scope="col">Total ($)</th><th scope="col">Payment</th></tr></thead>
      <tbody>
        <% for (String[] r : bookingRows) { String chip = chipClass(r[4]); String payChip = chipClass(r[6]); %>
        <tr>
          <td>#<%= esc(r[0]) %></td><td><%= dt(r[1]) %></td><td><%= esc(r[2]) %></td><td><%= esc(r[3]) %></td>
          <td><span class="chip <%= chip == null ? "" : chip %>"><%= esc(label(r[4])) %></span></td>
          <td><%= esc(r[5]) %></td>
          <td><% if (r[6] == null) { %>-<% } else { %><span class="chip <%= payChip == null ? "" : payChip %>"><%= esc(label(r[6])) %></span><% } %></td>
        </tr>
        <% } %>
      </tbody>
    </table>
  </div>
  <p class="hint">Showing up to 50 of the newest bookings.</p>
  <% } %>
<% } %>
</main>
</div>
</body>
</html>
