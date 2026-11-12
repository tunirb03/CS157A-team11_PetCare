<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%!
    private static final String[] ACCOUNT_STATUSES = {"ACTIVE", "SUSPENDED"};

    // "Suspended client 10: repeated no-shows"  becomes  "repeated no-shows"
    private String reasonOf(String description) {
        if (description == null) return "";
        int i = description.indexOf(": ");
        return i < 0 ? description : description.substring(i + 2);
    }

    private String money(double v) { return String.format("%,.2f", v); }
%>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    if (!isSitter(session)) { response.sendRedirect("dashboard.jsp"); return; }
    int userId = (Integer) session.getAttribute("userId");
    String message = null, error = null;

    // Suspend or reactivate a client account. Only client accounts can be changed here.
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        int clientId = intParam(request.getParameter("clientId"), 0);
        String reason = text(request.getParameter("reason"));
        try (Connection c = openConnection(application)) {
            String newStatus = "suspend".equals(action) ? "SUSPENDED" : "reactivate".equals(action) ? "ACTIVE" : null;
            if (newStatus == null) throw new Exception("Please choose suspend or reactivate.");
            if ("SUSPENDED".equals(newStatus) && (reason == null || reason.length() < 3))
                throw new Exception("Please give a reason for the suspension (at least 3 characters).");
            if (reason != null && reason.length() > 200) throw new Exception("The reason can be at most 200 characters.");

            String clientName;
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT u.FullName, u.AccountStatus FROM `user` u JOIN client cl ON cl.UserID=u.UserID WHERE u.UserID=?")) {
                p.setInt(1, clientId);
                try (ResultSet r = p.executeQuery()) {
                    if (!r.next()) throw new Exception("That client was not found.");
                    clientName = r.getString(1);
                    if (newStatus.equals(r.getString(2))) throw new Exception(clientName + " is already " + newStatus.toLowerCase() + ".");
                }
            }
            try (PreparedStatement p = c.prepareStatement(
                    "UPDATE `user` SET AccountStatus=? WHERE UserID=? AND UserID IN (SELECT UserID FROM client)")) {
                p.setString(1, newStatus); p.setInt(2, clientId);
                p.executeUpdate();
            }
            if ("SUSPENDED".equals(newStatus)) {
                audit(c, userId, "SUSPEND_ACCOUNT", "Suspended client " + clientId + ": " + reason);
                message = clientName + "'s account is suspended. They can no longer log in.";
            } else {
                audit(c, userId, "REACTIVATE_ACCOUNT", "Reactivated client " + clientId + ": " + (reason == null ? "no note" : reason));
                message = clientName + "'s account is active again.";
            }
        } catch (Exception e) { error = e.getMessage(); }
    }

    // Filters and the optional history view
    String search = text(request.getParameter("q"));
    String statusFilter = pick(request.getParameter("status"), ACCOUNT_STATUSES);
    int detailId = intParam(request.getParameter("client"), 0);

    List<String[]> clients = new ArrayList<>();
    int totalClients = 0, activeClients = 0, suspendedClients = 0;
    String[] detail = null;
    List<String[]> detailPets = new ArrayList<>(), detailBookings = new ArrayList<>(), detailActions = new ArrayList<>();
    String listError = null;

    try (Connection c = openConnection(application)) {
        // Totals for the summary cards
        try (PreparedStatement p = c.prepareStatement(
                "SELECT u.AccountStatus, COUNT(*) FROM client cl JOIN `user` u ON u.UserID=cl.UserID GROUP BY u.AccountStatus");
             ResultSet r = p.executeQuery()) {
            while (r.next()) {
                int n = r.getInt(2);
                totalClients += n;
                if ("SUSPENDED".equals(r.getString(1))) suspendedClients = n; else activeClients = n;
            }
        }

        // The client list: one row per client with booking counts, money paid, and the latest suspension reason
        StringBuilder where = new StringBuilder(" WHERE 1=1");
        List<Object> params = new ArrayList<>();
        params.add(userId); params.add(userId);
        if (search != null) { where.append(" AND (u.FullName LIKE ? OR u.Email LIKE ?)"); params.add("%" + search + "%"); params.add("%" + search + "%"); }
        if (statusFilter != null) { where.append(" AND u.AccountStatus=?"); params.add(statusFilter); }
        try (PreparedStatement p = c.prepareStatement(
                "SELECT u.UserID, u.FullName, u.Email, u.Phone, u.AccountStatus, u.CreatedAt, " +
                "COUNT(b.BookingID) AS Bookings, " +
                "COALESCE(SUM(CASE WHEN b.Status='COMPLETED' THEN 1 ELSE 0 END),0) AS Completed, " +
                "COALESCE(SUM(CASE WHEN b.Status IN ('CANCELLED','DECLINED') THEN 1 ELSE 0 END),0) AS Cancelled, " +
                "MAX(b.StartDateTime) AS LastBooking, " +
                "(SELECT COALESCE(SUM(pm.Amount),0) FROM payment pm JOIN booking b2 ON b2.BookingID=pm.BookingID " +
                "   WHERE b2.ClientID=u.UserID AND b2.SitterID=? AND pm.PaymentStatus='PAID') AS Paid, " +
                "(SELECT a.Description FROM audit_log a WHERE a.Action='SUSPEND_ACCOUNT' " +
                "   AND a.Description LIKE CONCAT('Suspended client ', u.UserID, ':%') ORDER BY a.LogID DESC LIMIT 1) AS LastReason " +
                "FROM client cl JOIN `user` u ON u.UserID=cl.UserID " +
                "LEFT JOIN booking b ON b.ClientID=cl.UserID AND b.SitterID=?" + where +
                " GROUP BY u.UserID, u.FullName, u.Email, u.Phone, u.AccountStatus, u.CreatedAt ORDER BY u.FullName")) {
            int i = 1;
            for (Object o : params) p.setObject(i++, o);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) clients.add(new String[]{
                    String.valueOf(r.getInt("UserID")), r.getString("FullName"), r.getString("Email"), r.getString("Phone"),
                    r.getString("AccountStatus"), r.getString("CreatedAt"), String.valueOf(r.getInt("Bookings")),
                    String.valueOf(r.getInt("Completed")), String.valueOf(r.getInt("Cancelled")), r.getString("LastBooking"),
                    money(r.getDouble("Paid")), r.getString("LastReason") });
            }
        }

        // History of one client: contact details, pets, bookings with this sitter, and past suspensions
        if (detailId > 0) {
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT u.FullName, u.Email, u.Phone, u.AccountStatus, u.CreatedAt, cl.EmergencyContactName, cl.EmergencyContactPhone " +
                    "FROM `user` u JOIN client cl ON cl.UserID=u.UserID WHERE u.UserID=?")) {
                p.setInt(1, detailId);
                try (ResultSet r = p.executeQuery()) {
                    if (r.next()) detail = new String[]{ String.valueOf(detailId), r.getString(1), r.getString(2), r.getString(3),
                        r.getString(4), r.getString(5), r.getString(6), r.getString(7) };
                }
            }
            if (detail != null) {
                try (PreparedStatement p = c.prepareStatement("SELECT PetName, Species, Breed FROM pet WHERE OwnerID=? ORDER BY PetName")) {
                    p.setInt(1, detailId);
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) detailPets.add(new String[]{ r.getString(1), r.getString(2), r.getString(3) });
                    }
                }
                try (PreparedStatement p = c.prepareStatement(
                        "SELECT b.BookingID, b.StartDateTime, b.Status, " +
                        "(SELECT GROUP_CONCAT(sv.ServiceName SEPARATOR ', ') FROM booking_service bs " +
                        "   JOIN service sv ON sv.ServiceID=bs.ServiceID WHERE bs.BookingID=b.BookingID) AS Services, " +
                        "(SELECT SUM(bs2.PriceAtBooking) FROM booking_service bs2 WHERE bs2.BookingID=b.BookingID) AS Total, " +
                        "pm.PaymentStatus " +
                        "FROM booking b LEFT JOIN payment pm ON pm.BookingID=b.BookingID " +
                        "WHERE b.ClientID=? AND b.SitterID=? ORDER BY b.StartDateTime DESC")) {
                    p.setInt(1, detailId); p.setInt(2, userId);
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) detailBookings.add(new String[]{ String.valueOf(r.getInt(1)), r.getString(2), r.getString(3),
                            r.getString(4), money(r.getDouble(5)), r.getString(6) });
                    }
                }
                try (PreparedStatement p = c.prepareStatement(
                        "SELECT a.Action, a.Description, a.ActionTime, u.FullName FROM audit_log a JOIN `user` u ON u.UserID=a.UserID " +
                        "WHERE a.Action IN ('SUSPEND_ACCOUNT','REACTIVATE_ACCOUNT') " +
                        "AND (a.Description LIKE ? OR a.Description LIKE ?) ORDER BY a.LogID DESC")) {
                    p.setString(1, "Suspended client " + detailId + ":%");
                    p.setString(2, "Reactivated client " + detailId + ":%");
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) detailActions.add(new String[]{ r.getString(1), reasonOf(r.getString(2)), r.getString(3), r.getString(4) });
                    }
                }
            }
        }
    } catch (Exception e) { listError = e.getMessage(); }
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Client accounts | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1>Client accounts</h1>
  <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>
  <% if (listError != null) { %><p class="notice notice-error"><%= esc(listError) %></p><% } %>

  <div class="cards">
    <article class="card"><h3>All clients</h3><p><strong><%= totalClients %></strong></p></article>
    <article class="card"><h3>Active</h3><p><strong><%= activeClients %></strong></p></article>
    <article class="card"><h3>Suspended</h3><p><strong><%= suspendedClients %></strong></p></article>
  </div>

<% if (detailId > 0 && detail == null && listError == null) { %>
  <p class="notice notice-error">That client was not found.</p>
<% } %>
<% if (detail != null) {
     String detailChip = "SUSPENDED".equals(detail[4]) ? "chip-cancelled" : "chip-confirmed"; %>
  <section class="panel">
    <h2>History: <%= esc(detail[1]) %> <span class="chip <%= detailChip %>"><%= esc(label(detail[4])) %></span></h2>
    <p class="card-meta"><%= esc(detail[2]) %> · <%= detail[3] == null ? "no phone" : esc(detail[3]) %> · Member since <%= dt(detail[5]) %></p>
    <p class="card-meta">Emergency contact: <%= detail[6] == null ? "not given" : esc(detail[6]) + (detail[7] == null ? "" : " (" + esc(detail[7]) + ")") %></p>
    <p class="card-meta">Pets:
      <% if (detailPets.isEmpty()) { %>none saved<% } else { for (int i = 0; i < detailPets.size(); i++) { String[] pt = detailPets.get(i); %><%= i > 0 ? ", " : "" %><%= esc(pt[0]) %> (<%= esc(pt[1]) %>)<% } } %>
    </p>

    <h2 class="section-title">Bookings</h2>
    <% if (detailBookings.isEmpty()) { %><p class="muted">This client has no bookings yet.</p><% } else { %>
    <div class="data-wrap" tabindex="0" aria-label="Client bookings">
      <table class="data">
        <thead><tr><th scope="col">Booking</th><th scope="col">Starts</th><th scope="col">Services</th><th scope="col">Status</th><th scope="col">Total ($)</th><th scope="col">Payment</th></tr></thead>
        <tbody>
          <% for (String[] bk : detailBookings) { String chip = chipClass(bk[2]); String payChip = chipClass(bk[5]); %>
          <tr>
            <td>#<%= esc(bk[0]) %></td><td><%= dt(bk[1]) %></td><td><%= esc(bk[3]) %></td>
            <td><span class="chip <%= chip == null ? "" : chip %>"><%= esc(label(bk[2])) %></span></td>
            <td><%= esc(bk[4]) %></td>
            <td><% if (bk[5] == null) { %>-<% } else { %><span class="chip <%= payChip == null ? "" : payChip %>"><%= esc(label(bk[5])) %></span><% } %></td>
          </tr>
          <% } %>
        </tbody>
      </table>
    </div>
    <% } %>

    <h2 class="section-title">Account actions</h2>
    <% if (detailActions.isEmpty()) { %><p class="muted">This account has never been suspended.</p><% } else { %>
    <div class="data-wrap" tabindex="0" aria-label="Account actions">
      <table class="data">
        <thead><tr><th scope="col">When</th><th scope="col">Action</th><th scope="col">Reason or note</th><th scope="col">By</th></tr></thead>
        <tbody>
          <% for (String[] ac : detailActions) { %>
          <tr><td><%= dt(ac[2]) %></td><td><%= "SUSPEND_ACCOUNT".equals(ac[0]) ? "Suspended" : "Reactivated" %></td><td><%= esc(ac[1]) %></td><td><%= esc(ac[3]) %></td></tr>
          <% } %>
        </tbody>
      </table>
    </div>
    <% } %>
    <p><a class="btn btn-outline btn-small" href="clients.jsp">Close history</a></p>
  </section>
<% } %>

  <section class="panel">
    <h2>Find a client</h2>
    <form method="get" class="form-grid">
      <label>Name or email <input type="text" name="q" value="<%= esc(search) %>" maxlength="100"></label>
      <label>Account status
        <select name="status"><option value="">All</option><%= options(ACCOUNT_STATUSES, statusFilter) %></select>
      </label>
      <div class="wide">
        <button class="btn btn-primary" type="submit">Search</button>
        <a class="btn btn-outline" href="clients.jsp">Clear</a>
      </div>
    </form>
  </section>

  <h2 class="section-title">Clients</h2>
  <div class="cards">
    <% for (String[] cl : clients) {
         boolean suspended = "SUSPENDED".equals(cl[4]);
         String chip = suspended ? "chip-cancelled" : "chip-confirmed"; %>
    <article class="card">
      <h3><%= esc(cl[1]) %> <span class="chip <%= chip %>"><%= esc(label(cl[4])) %></span></h3>
      <p class="card-meta"><%= esc(cl[2]) %> · <%= cl[3] == null ? "no phone" : esc(cl[3]) %> · Member since <%= dt(cl[5]) %></p>
      <p class="card-meta">Bookings: <strong><%= esc(cl[6]) %></strong> · Completed: <strong><%= esc(cl[7]) %></strong> · Cancelled or declined: <strong><%= esc(cl[8]) %></strong> · Paid: <strong>$<%= esc(cl[10]) %></strong></p>
      <p class="card-meta">Last booking: <%= cl[9] == null ? "none" : dt(cl[9]) %></p>
      <% if (suspended && cl[11] != null) { %><p>Suspension reason: <%= esc(reasonOf(cl[11])) %></p><% } %>
      <% if (!suspended) { %>
      <form method="post" class="card-actions inline-form" onsubmit="return confirm('Suspend this account? The client will not be able to log in.');">
        <input type="hidden" name="action" value="suspend"><input type="hidden" name="clientId" value="<%= esc(cl[0]) %>">
        <label class="sr-only" for="reason-<%= esc(cl[0]) %>">Reason for suspension</label>
        <input id="reason-<%= esc(cl[0]) %>" type="text" name="reason" placeholder="Reason (required)" minlength="3" maxlength="200" required>
        <button class="btn btn-outline btn-small" type="submit">Suspend account</button>
      </form>
      <% } else { %>
      <form method="post" class="card-actions inline-form">
        <input type="hidden" name="action" value="reactivate"><input type="hidden" name="clientId" value="<%= esc(cl[0]) %>">
        <label class="sr-only" for="note-<%= esc(cl[0]) %>">Note</label>
        <input id="note-<%= esc(cl[0]) %>" type="text" name="reason" placeholder="Note (optional)" maxlength="200">
        <button class="btn btn-primary btn-small" type="submit">Reactivate account</button>
      </form>
      <% } %>
      <div class="card-actions"><a class="btn btn-outline btn-small" href="clients.jsp?client=<%= esc(cl[0]) %>">View history</a></div>
    </article>
    <% } %>
    <% if (clients.isEmpty()) { %><p class="muted">No clients match your search.</p><% } %>
  </div>
</main>
</div>
</body>
</html>
