<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%!
    private static final String[] EVENT_TYPES = {"DROP_OFF", "PICK_UP"};

    // Reads a DATETIME that came back from MySQL as text, like "2026-08-01 09:05:00"
    private java.time.LocalDateTime fromDb(String s) {
        if (s == null) return null;
        try { return java.time.LocalDateTime.parse(s.trim().replace(' ', 'T').replaceAll("\\.\\d+$", "")); }
        catch (Exception e) { return null; }
    }

    // Turns minutes into text like "2 days 3 h 15 min"
    private String duration(long minutes) {
        if (minutes < 0) return "";
        long d = minutes / 1440, h = (minutes % 1440) / 60, m = minutes % 60;
        StringBuilder b = new StringBuilder();
        if (d > 0) b.append(d).append(d == 1 ? " day " : " days ");
        if (h > 0 || d > 0) b.append(h).append(" h ");
        b.append(m).append(" min");
        return b.toString().trim();
    }
%>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    int userId = (Integer) session.getAttribute("userId");
    boolean sitterUser = isSitter(session);
    String ownColumn = sitterUser ? "SitterID" : "ClientID";
    String message = null, error = null;

    // Only the sitter records or removes events
    if ("POST".equalsIgnoreCase(request.getMethod()) && sitterUser) {
        String action = request.getParameter("action");
        try (Connection c = openConnection(application)) {
            if ("delete".equals(action)) {
                int bookingId = intParam(request.getParameter("bookingId"), 0);
                int petId = intParam(request.getParameter("petId"), 0);
                String type = pick(request.getParameter("type"), EVENT_TYPES);
                if (type == null) throw new Exception("Please pick a valid event type.");
                try (PreparedStatement p = c.prepareStatement(
                        "DELETE FROM care_event WHERE BookingID=? AND PetID=? AND EventType=? " +
                        "AND BookingID IN (SELECT BookingID FROM booking WHERE SitterID=?)")) {
                    p.setInt(1, bookingId); p.setInt(2, petId); p.setString(3, type); p.setInt(4, userId);
                    if (p.executeUpdate() == 0) throw new Exception("That event was not found.");
                }
                audit(c, userId, "DELETE_CARE_EVENT", "Removed " + label(type).toLowerCase() + " for pet " + petId + " on booking " + bookingId);
                message = label(type) + " removed.";
            } else {
                String[] pair = String.valueOf(request.getParameter("stay")).split("_");
                int bookingId = pair.length == 2 ? intParam(pair[0], 0) : 0;
                int petId = pair.length == 2 ? intParam(pair[1], 0) : 0;
                String type = pick(request.getParameter("type"), EVENT_TYPES);
                java.time.LocalDateTime when = parseLocal(request.getParameter("eventTime"));
                if (bookingId == 0 || petId == 0 || type == null || when == null)
                    throw new Exception("Please pick a pet, an event, and a date and time.");
                if (when.isAfter(java.time.LocalDateTime.now().plusMinutes(5)))
                    throw new Exception("The event time can't be in the future.");

                // The pet must be on one of this sitter's bookings, and the booking must be confirmed
                String bookingStatus;
                try (PreparedStatement p = c.prepareStatement(
                        "SELECT b.Status FROM booking b JOIN booking_pet bp ON bp.BookingID=b.BookingID " +
                        "WHERE b.BookingID=? AND bp.PetID=? AND b.SitterID=?")) {
                    p.setInt(1, bookingId); p.setInt(2, petId); p.setInt(3, userId);
                    try (ResultSet r = p.executeQuery()) {
                        if (!r.next()) throw new Exception("That pet is not on one of your bookings.");
                        bookingStatus = r.getString(1);
                    }
                }
                if (!("CONFIRMED".equals(bookingStatus) || "IN_PROGRESS".equals(bookingStatus) || "COMPLETED".equals(bookingStatus)))
                    throw new Exception("Events can be recorded after you confirm the booking.");

                // What is already recorded for this pet on this booking?
                java.time.LocalDateTime dropOff = null, pickUp = null;
                try (PreparedStatement p = c.prepareStatement("SELECT EventType, EventTime FROM care_event WHERE BookingID=? AND PetID=?")) {
                    p.setInt(1, bookingId); p.setInt(2, petId);
                    try (ResultSet r = p.executeQuery()) {
                        while (r.next()) {
                            if ("DROP_OFF".equals(r.getString(1))) dropOff = fromDb(r.getString(2));
                            else pickUp = fromDb(r.getString(2));
                        }
                    }
                }
                if ("DROP_OFF".equals(type)) {
                    if (dropOff != null) throw new Exception("A drop-off is already recorded for this pet. Remove it first to change the time.");
                    if (pickUp != null && !when.isBefore(pickUp)) throw new Exception("The drop-off must be before the pick-up.");
                } else {
                    if (pickUp != null) throw new Exception("A pick-up is already recorded for this pet. Remove it first to change the time.");
                    if (dropOff == null) throw new Exception("Record the drop-off first.");
                    if (!when.isAfter(dropOff)) throw new Exception("The pick-up must be after the drop-off.");
                }

                try (PreparedStatement p = c.prepareStatement("INSERT INTO care_event(BookingID,PetID,EventType,EventTime) VALUES(?,?,?,?)")) {
                    p.setInt(1, bookingId); p.setInt(2, petId); p.setString(3, type); p.setObject(4, when);
                    p.executeUpdate();
                } catch (SQLIntegrityConstraintViolationException dup) {
                    throw new Exception("That " + label(type).toLowerCase() + " is already recorded for this pet. Remove it first to change the time.");
                }
                audit(c, userId, "RECORD_CARE_EVENT", label(type) + " for pet " + petId + " on booking " + bookingId);
                message = label(type) + " recorded for booking #" + bookingId + ".";
            }
        } catch (Exception e) { error = e.getMessage(); }
    }

    // What the page shows: the sitter's pets waiting for an event, and the timeline of recorded events
    List<String[]> stays = new ArrayList<>();
    List<String[]> rows = new ArrayList<>();
    String listError = null;
    try (Connection c = openConnection(application)) {
        String servicesSql = "(SELECT GROUP_CONCAT(sv.ServiceName SEPARATOR ', ') FROM booking_service bs " +
                             "JOIN service sv ON sv.ServiceID=bs.ServiceID WHERE bs.BookingID=b.BookingID)";
        if (sitterUser) {
            try (PreparedStatement p = c.prepareStatement(
                    "SELECT b.BookingID, bp.PetID, p.PetName, p.Species, b.StartDateTime, " + servicesSql + " AS Services " +
                    "FROM booking b JOIN booking_pet bp ON bp.BookingID=b.BookingID JOIN pet p ON p.PetID=bp.PetID " +
                    "WHERE b.SitterID=? AND b.Status IN ('CONFIRMED','IN_PROGRESS','COMPLETED') " +
                    "ORDER BY b.StartDateTime DESC, p.PetName")) {
                p.setInt(1, userId);
                try (ResultSet r = p.executeQuery()) {
                    while (r.next()) stays.add(new String[]{
                        String.valueOf(r.getInt("BookingID")), String.valueOf(r.getInt("PetID")), r.getString("PetName"),
                        r.getString("Species"), r.getString("StartDateTime"), r.getString("Services") });
                }
            }
        }
        // One row per pet per booking; the two LEFT JOINs pick up that pet's drop-off and pick-up
        try (PreparedStatement p = c.prepareStatement(
                "SELECT b.BookingID, bp.PetID, p.PetName, b.Status, b.StartDateTime, b.EndDateTime, " +
                (sitterUser ? "cu.FullName" : "st.BusinessName") + " AS Other, " + servicesSql + " AS Services, " +
                "dp.EventTime AS DropOff, pu.EventTime AS PickUp " +
                "FROM booking_pet bp JOIN booking b ON b.BookingID=bp.BookingID JOIN pet p ON p.PetID=bp.PetID " +
                "JOIN `user` cu ON cu.UserID=b.ClientID JOIN sitter st ON st.UserID=b.SitterID " +
                "LEFT JOIN care_event dp ON dp.BookingID=bp.BookingID AND dp.PetID=bp.PetID AND dp.EventType='DROP_OFF' " +
                "LEFT JOIN care_event pu ON pu.BookingID=bp.BookingID AND pu.PetID=bp.PetID AND pu.EventType='PICK_UP' " +
                "WHERE b." + ownColumn + "=? AND (dp.EventID IS NOT NULL OR pu.EventID IS NOT NULL) " +
                "ORDER BY b.StartDateTime DESC, p.PetName")) {
            p.setInt(1, userId);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) rows.add(new String[]{
                    String.valueOf(r.getInt("BookingID")), String.valueOf(r.getInt("PetID")), r.getString("PetName"),
                    r.getString("Status"), r.getString("StartDateTime"), r.getString("EndDateTime"),
                    r.getString("Other"), r.getString("Services"), r.getString("DropOff"), r.getString("PickUp") });
            }
        }
    } catch (Exception e) { listError = e.getMessage(); }
    String nowLocal = java.time.LocalDateTime.now().withSecond(0).withNano(0).toString();
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Drop-off and pick-up | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1>Drop-off and pick-up</h1>
  <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>
  <% if (listError != null) { %><p class="notice notice-error"><%= esc(listError) %></p><% } %>

<% if (sitterUser) { %>
  <section class="panel">
    <h2>Record an event</h2>
    <% if (stays.isEmpty()) { %>
      <p class="muted">No confirmed bookings yet. Confirm a booking first, then record when each pet arrives and leaves.</p>
    <% } else { %>
    <form method="post" class="form-grid">
      <input type="hidden" name="action" value="record">
      <label class="wide">Booking and pet
        <select name="stay" required>
          <option value="">Choose a pet</option>
          <% for (String[] s : stays) { %>
          <option value="<%= esc(s[0]) %>_<%= esc(s[1]) %>">#<%= esc(s[0]) %> · <%= esc(s[2]) %> (<%= esc(s[3]) %>) · <%= esc(s[5]) %> · <%= dt(s[4]) %></option>
          <% } %>
        </select>
      </label>
      <label>Event
        <select name="type"><%= options(EVENT_TYPES, null) %></select>
      </label>
      <label>Date and time <input type="datetime-local" name="eventTime" value="<%= esc(nowLocal) %>" required></label>
      <div class="wide"><p class="hint">Record the drop-off first, then the pick-up. The actual care time is worked out from the two.</p></div>
      <div class="wide"><button class="btn btn-primary" type="submit">Save event</button></div>
    </form>
    <% } %>
  </section>
<% } %>

  <h2 class="section-title">Timeline</h2>
  <div class="cards">
    <% for (String[] r : rows) {
         java.time.LocalDateTime dropOff = fromDb(r[8]), pickUp = fromDb(r[9]);
         String chip = chipClass(r[3]); %>
    <article class="card">
      <h3>Booking #<%= esc(r[0]) %> · <%= esc(r[2]) %> <span class="chip <%= chip == null ? "" : chip %>"><%= esc(label(r[3])) %></span></h3>
      <p class="card-meta"><%= esc(r[7]) %> · <%= sitterUser ? "Client: " : "Sitter: " %><%= esc(r[6]) %></p>
      <p class="card-meta">Booked: <%= dt(r[4]) %> to <%= dt(r[5]) %></p>
      <p>Drop-off: <strong><%= r[8] == null ? "not recorded" : dt(r[8]) %></strong></p>
      <% if (sitterUser && r[8] != null) { %>
      <form method="post" class="card-actions inline-form" onsubmit="return confirm('Remove this drop-off?');">
        <input type="hidden" name="action" value="delete"><input type="hidden" name="type" value="DROP_OFF">
        <input type="hidden" name="bookingId" value="<%= esc(r[0]) %>"><input type="hidden" name="petId" value="<%= esc(r[1]) %>">
        <button class="btn btn-outline btn-small" type="submit">Remove drop-off</button>
      </form>
      <% } %>
      <p>Pick-up: <strong><%= r[9] == null ? "not recorded" : dt(r[9]) %></strong></p>
      <% if (sitterUser && r[9] != null) { %>
      <form method="post" class="card-actions inline-form" onsubmit="return confirm('Remove this pick-up?');">
        <input type="hidden" name="action" value="delete"><input type="hidden" name="type" value="PICK_UP">
        <input type="hidden" name="bookingId" value="<%= esc(r[0]) %>"><input type="hidden" name="petId" value="<%= esc(r[1]) %>">
        <button class="btn btn-outline btn-small" type="submit">Remove pick-up</button>
      </form>
      <% } %>
      <% if (dropOff != null && pickUp != null) { %>
      <p class="card-meta">Actual care time: <strong><%= esc(duration(java.time.Duration.between(dropOff, pickUp).toMinutes())) %></strong></p>
      <% } else if (dropOff != null) { %>
      <p class="muted">The pet is still in care.</p>
      <% } %>
    </article>
    <% } %>
    <% if (rows.isEmpty()) { %><p class="muted">No drop-offs or pick-ups have been recorded yet.</p><% } %>
  </div>
</main>
</div>
</body>
</html>
