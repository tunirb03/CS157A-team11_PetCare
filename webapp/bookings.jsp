<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%!
    private static final String[] ADDRESS_TYPES = {"HOME", "OTHER"};

    // After a failed request, refill the box with what the user typed so they don't have to start over
    private String keep(jakarta.servlet.http.HttpServletRequest r, boolean on, String name) {
        return on ? esc(r.getParameter(name)) : "";
    }

    // Sample AuditLog rows use names like CONFIRM_BOOKING, so status changes are logged the same way
    private String auditAction(String status) {
        if ("CONFIRMED".equals(status)) return "CONFIRM_BOOKING";
        if ("DECLINED".equals(status)) return "DECLINE_BOOKING";
        if ("CANCELLED".equals(status)) return "CANCEL_BOOKING";
        return "UPDATE_BOOKING";
    }
%>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    int userId = (Integer) session.getAttribute("userId");   // always from the session, never from the URL
    boolean sitterUser = isSitter(session);
    String message = null, error = null;
    boolean createFailed = false;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        int bookingId = intParam(request.getParameter("bookingId"), 0);
        Connection conn = null;
        try {
            conn = openConnection(application);

            if ("status".equals(action) && sitterUser) {
                // A sitter can change the status of bookings assigned to them only
                String status = pick(request.getParameter("status"), BOOKING_STATUSES);
                if (status == null) throw new Exception("Please pick a valid status.");
                try (PreparedStatement ps = conn.prepareStatement("UPDATE Booking SET Status=? WHERE BookingID=? AND SitterID=?")) {
                    ps.setString(1, status); ps.setInt(2, bookingId); ps.setInt(3, userId);
                    if (ps.executeUpdate() == 0) throw new Exception("That booking was not found.");
                }
                audit(conn, userId, auditAction(status), "Marked booking " + bookingId + " as " + status);
                message = "Booking #" + bookingId + " is now " + label(status).toLowerCase() + ".";

            } else if ("cancel".equals(action) && !sitterUser) {
                // An owner can cancel their own booking while it is still requested or confirmed
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Booking SET Status='CANCELLED' WHERE BookingID=? AND ClientID=? AND Status IN ('REQUESTED','CONFIRMED')")) {
                    ps.setInt(1, bookingId); ps.setInt(2, userId);
                    if (ps.executeUpdate() == 0) throw new Exception("That booking can't be cancelled anymore.");
                }
                audit(conn, userId, "CANCEL_BOOKING", "Client cancelled booking " + bookingId);
                message = "Booking #" + bookingId + " was cancelled.";

            } else if ("create".equals(action) && !sitterUser) {
                createFailed = true;   // set back to false once everything is saved

                // 1. Read and check the form
                List<Integer> petIds = new ArrayList<>();
                String[] picked = request.getParameterValues("petId");
                if (picked != null) for (String p : picked) { int id = intParam(p, 0); if (id > 0 && !petIds.contains(id)) petIds.add(id); }
                if (petIds.isEmpty()) throw new Exception("Please pick at least one pet.");
                int serviceId = intParam(request.getParameter("serviceId"), 0);
                java.time.LocalDateTime start = parseLocal(request.getParameter("startTime"));
                java.time.LocalDateTime end = parseLocal(request.getParameter("endTime"));
                if (start == null || end == null) throw new Exception("Please enter a start and end time.");
                if (!end.isAfter(start)) throw new Exception("The end time must be after the start time.");

                // 2. Every pet must belong to this owner
                for (int petId : petIds) {
                    try (PreparedStatement ps = conn.prepareStatement("SELECT 1 FROM Pet WHERE PetID=? AND OwnerID=?")) {
                        ps.setInt(1, petId); ps.setInt(2, userId);
                        try (ResultSet r = ps.executeQuery()) { if (!r.next()) throw new Exception("Please pick only your own pets."); }
                    }
                }

                // 3. The service must be available. Its sitter becomes the booking's sitter.
                int sitterId, capacity; java.math.BigDecimal price; String serviceName;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT SitterID, Price, Capacity, ServiceName FROM Service WHERE ServiceID=? AND AvailabilityStatus='AVAILABLE'")) {
                    ps.setInt(1, serviceId);
                    try (ResultSet r = ps.executeQuery()) {
                        if (!r.next()) throw new Exception("That service is not available.");
                        sitterId = r.getInt("SitterID"); price = r.getBigDecimal("Price");
                        capacity = r.getInt("Capacity"); serviceName = r.getString("ServiceName");
                    }
                }

                // 4. Capacity: count active bookings of this service that overlap the requested time
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM Booking b JOIN BookingService bs ON bs.BookingID=b.BookingID " +
                        "WHERE bs.ServiceID=? AND b.Status IN ('REQUESTED','CONFIRMED','IN_PROGRESS') AND b.StartDateTime < ? AND b.EndDateTime > ?")) {
                    ps.setInt(1, serviceId); ps.setObject(2, end); ps.setObject(3, start);
                    try (ResultSet r = ps.executeQuery()) { r.next(); if (r.getInt(1) >= capacity) throw new Exception("That service is fully booked at that time. Try another time."); }
                }

                // 5. A pet can't be in two active bookings at the same time
                for (int petId : petIds) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "SELECT p.PetName FROM Booking b JOIN BookingPet bp ON bp.BookingID=b.BookingID JOIN Pet p ON p.PetID=bp.PetID " +
                            "WHERE bp.PetID=? AND b.Status IN ('REQUESTED','CONFIRMED','IN_PROGRESS') AND b.StartDateTime < ? AND b.EndDateTime > ?")) {
                        ps.setInt(1, petId); ps.setObject(2, end); ps.setObject(3, start);
                        try (ResultSet r = ps.executeQuery()) { if (r.next()) throw new Exception(r.getString(1) + " already has a booking at that time."); }
                    }
                }

                // 6. Save everything in one transaction: all rows are saved, or none are
                conn.setAutoCommit(false);

                int addressId;
                String addressChoice = request.getParameter("addressId");
                if ("new".equals(addressChoice) || addressChoice == null) {
                    String street = text(request.getParameter("street")), city = text(request.getParameter("city"));
                    String state = text(request.getParameter("state")), zip = text(request.getParameter("zip"));
                    if (street == null || city == null || state == null || zip == null)
                        throw new Exception("Please fill in the street, city, state, and zip code for the new address.");
                    if (!state.matches("[A-Za-z]{2}")) throw new Exception("State must be 2 letters, like CA.");
                    String type = pick(request.getParameter("addressType"), ADDRESS_TYPES);
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO Address(UserID,Street,City,State,ZipCode,AddressType) VALUES(?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                        ps.setInt(1, userId); ps.setString(2, street); ps.setString(3, city);
                        ps.setString(4, state.toUpperCase()); ps.setString(5, zip); ps.setString(6, type == null ? "HOME" : type);
                        ps.executeUpdate();
                        try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); addressId = keys.getInt(1); }
                    }
                } else {
                    addressId = intParam(addressChoice, 0);
                    try (PreparedStatement ps = conn.prepareStatement("SELECT 1 FROM Address WHERE AddressID=? AND UserID=?")) {
                        ps.setInt(1, addressId); ps.setInt(2, userId);
                        try (ResultSet r = ps.executeQuery()) { if (!r.next()) throw new Exception("Please pick one of your own addresses."); }
                    }
                }

                int newId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO Booking(ClientID,SitterID,AddressID,StartDateTime,EndDateTime,Status) VALUES(?,?,?,?,?,'REQUESTED')",
                        Statement.RETURN_GENERATED_KEYS)) {
                    ps.setInt(1, userId); ps.setInt(2, sitterId); ps.setInt(3, addressId);
                    ps.setObject(4, start); ps.setObject(5, end);
                    ps.executeUpdate();
                    try (ResultSet keys = ps.getGeneratedKeys()) { keys.next(); newId = keys.getInt(1); }
                }

                try (PreparedStatement ps = conn.prepareStatement("INSERT INTO BookingPet(BookingID,PetID) VALUES(?,?)")) {
                    for (int petId : petIds) { ps.setInt(1, newId); ps.setInt(2, petId); ps.executeUpdate(); }
                }

                // PriceAtBooking keeps today's price, even if the sitter changes it later
                try (PreparedStatement ps = conn.prepareStatement("INSERT INTO BookingService(BookingID,ServiceID,PriceAtBooking) VALUES(?,?,?)")) {
                    ps.setInt(1, newId); ps.setInt(2, serviceId); ps.setBigDecimal(3, price); ps.executeUpdate();
                }

                // Care instructions are saved once per pet (CareInstruction points to BookingPet)
                String feeding = text(request.getParameter("feeding")), medication = text(request.getParameter("medication"));
                String behavior = text(request.getParameter("behavior")), emergency = text(request.getParameter("emergency"));
                if (feeding != null || medication != null || behavior != null || emergency != null) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO CareInstruction(BookingID,PetID,FeedingInstructions,MedicationNeeds,BehavioralNotes,EmergencyNotes) VALUES(?,?,?,?,?,?)")) {
                        for (int petId : petIds) {
                            ps.setInt(1, newId); ps.setInt(2, petId); ps.setString(3, feeding);
                            ps.setString(4, medication); ps.setString(5, behavior); ps.setString(6, emergency);
                            ps.executeUpdate();
                        }
                    }
                }

                audit(conn, userId, "CREATE_BOOKING", "Requested booking " + newId + " for " + serviceName);
                conn.commit();
                conn.setAutoCommit(true);
                createFailed = false;
                message = "Booking #" + newId + " was requested. The sitter will confirm it.";
            }
        } catch (Exception e) {
            error = e.getMessage();
            try { if (conn != null && !conn.getAutoCommit()) conn.rollback(); } catch (Exception ignored) { }
        } finally {
            try { if (conn != null) conn.close(); } catch (Exception ignored) { }
        }
    }
    int preselectService = intParam(request.getParameter("serviceId"), 0);
%>
<!DOCTYPE html>
<html lang="en">
<head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Bookings | PetCare</title></head>
<body>
<%@ include file="/WEB-INF/jspf/sound.jspf" %>
<div class="shell">
<%@ include file="/WEB-INF/jspf/sidebar.jspf" %>
<main class="main">
  <p class="crumb"><a href="dashboard.jsp">Dashboard</a></p>
  <h1><%= sitterUser ? "Manage bookings" : "My bookings" %></h1>
  <% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %>
  <% if (error != null) { %><p class="notice notice-error"><%= esc(error) %></p><% } %>

<% if (!sitterUser) {
     // Load this owner's pets, the available services, and their saved addresses for the form
     List<String[]> myPets = new ArrayList<>(), services = new ArrayList<>(), addresses = new ArrayList<>();
     try (Connection c = openConnection(application)) {
         try (PreparedStatement p = c.prepareStatement("SELECT PetID, PetName, Species FROM Pet WHERE OwnerID=? ORDER BY PetName")) {
             p.setInt(1, userId);
             try (ResultSet r = p.executeQuery()) { while (r.next()) myPets.add(new String[]{r.getString(1), r.getString(2), r.getString(3)}); }
         }
         try (PreparedStatement p = c.prepareStatement(
                 "SELECT sv.ServiceID, sv.ServiceName, st.BusinessName, sv.Price FROM Service sv JOIN Sitter st ON st.UserID=sv.SitterID " +
                 "WHERE sv.AvailabilityStatus='AVAILABLE' ORDER BY sv.ServiceName, st.BusinessName");
              ResultSet r = p.executeQuery()) {
             while (r.next()) services.add(new String[]{r.getString(1), r.getString(2), r.getString(3), String.format("%.2f", r.getDouble(4))});
         }
         try (PreparedStatement p = c.prepareStatement("SELECT AddressID, Street, City, AddressType FROM Address WHERE UserID=? ORDER BY AddressID")) {
             p.setInt(1, userId);
             try (ResultSet r = p.executeQuery()) { while (r.next()) addresses.add(new String[]{r.getString(1), r.getString(2), r.getString(3), r.getString(4)}); }
         }
     } catch (Exception e) { %><p class="notice notice-error"><%= esc(e.getMessage()) %></p><% }
     String keptService = createFailed ? request.getParameter("serviceId") : String.valueOf(preselectService);
     List<String> keptPets = createFailed && request.getParameterValues("petId") != null ? Arrays.asList(request.getParameterValues("petId")) : new ArrayList<String>();
     String keptAddress = createFailed ? request.getParameter("addressId") : null;
%>
  <section class="panel" id="request">
    <h2>Request a booking</h2>
  <% if (myPets.isEmpty()) { %>
    <p>You need to add a pet before you can book. <a href="pets.jsp">Add a pet</a></p>
  <% } else { %>
    <form method="post" action="bookings.jsp" class="form-grid">
      <input type="hidden" name="action" value="create">

      <fieldset class="wide">
        <legend>Which pets?</legend>
        <div class="checks">
        <% for (String[] p : myPets) { %>
          <label class="check"><input type="checkbox" name="petId" value="<%= p[0] %>" <%= keptPets.contains(p[0]) || myPets.size() == 1 ? "checked" : "" %>> <%= esc(p[1]) %> <span class="muted">(<%= esc(p[2]) %>)</span></label>
        <% } %>
        </div>
      </fieldset>

      <label class="wide">Service
        <select name="serviceId" required>
          <option value="">Choose a service</option>
          <% for (String[] s : services) { %>
            <option value="<%= s[0] %>" <%= s[0].equals(keptService) ? "selected" : "" %>><%= esc(s[1]) %> by <%= esc(s[2]) %> ($<%= s[3] %>)</option>
          <% } %>
        </select>
      </label>
      <label>Start <input name="startTime" type="datetime-local" value="<%= keep(request, createFailed, "startTime") %>" required></label>
      <label>End <input name="endTime" type="datetime-local" value="<%= keep(request, createFailed, "endTime") %>" required></label>

      <fieldset class="wide">
        <legend>Where?</legend>
        <label>Address
          <select name="addressId">
            <% for (String[] a : addresses) { %>
              <option value="<%= a[0] %>" <%= a[0].equals(keptAddress) ? "selected" : "" %>><%= esc(a[1]) %>, <%= esc(a[2]) %> (<%= esc(label(a[3])) %>)</option>
            <% } %>
            <option value="new" <%= addresses.isEmpty() || "new".equals(keptAddress) ? "selected" : "" %>>Add a new address (fill in below)</option>
          </select>
        </label>
        <p class="hint">Only fill these in if you picked "Add a new address".</p>
        <div class="form-grid">
          <label class="wide">Street <input name="street" maxlength="150" value="<%= keep(request, createFailed, "street") %>"></label>
          <label>City <input name="city" maxlength="60" value="<%= keep(request, createFailed, "city") %>"></label>
          <label>State <input name="state" maxlength="2" placeholder="CA" value="<%= keep(request, createFailed, "state") %>"></label>
          <label>Zip code <input name="zip" maxlength="10" value="<%= keep(request, createFailed, "zip") %>"></label>
          <label>Address type <select name="addressType"><%= options(ADDRESS_TYPES, createFailed ? request.getParameter("addressType") : "HOME") %></select></label>
        </div>
      </fieldset>

      <fieldset class="wide">
        <legend>Care instructions <span class="muted">(optional, saved for each pet you picked)</span></legend>
        <div class="form-grid">
          <label>Feeding <textarea name="feeding" maxlength="255"><%= keep(request, createFailed, "feeding") %></textarea></label>
          <label>Medication <textarea name="medication" maxlength="255"><%= keep(request, createFailed, "medication") %></textarea></label>
          <label>Behavior <textarea name="behavior" maxlength="255"><%= keep(request, createFailed, "behavior") %></textarea></label>
          <label>Emergency <textarea name="emergency" maxlength="255"><%= keep(request, createFailed, "emergency") %></textarea></label>
        </div>
      </fieldset>

      <div class="wide"><button class="btn btn-primary" type="submit">Request booking</button></div>
    </form>
  <% } %>
  </section>
<% } %>

  <h2 class="section-title"><%= sitterUser ? "Bookings assigned to me" : "Booking history" %></h2>
  <div class="cards">
<%
    // Care instructions for this user's bookings, grouped by BookingID
    Map<Integer, List<String[]>> care = new HashMap<>();
    String careSql = "SELECT ci.BookingID, p.PetName, ci.FeedingInstructions, ci.MedicationNeeds, ci.BehavioralNotes, ci.EmergencyNotes " +
        "FROM CareInstruction ci JOIN Pet p ON p.PetID=ci.PetID JOIN Booking b ON b.BookingID=ci.BookingID " +
        "WHERE " + (sitterUser ? "b.SitterID=?" : "b.ClientID=?") + " ORDER BY p.PetName";

    // One row per booking. Pets and services come from the BookingPet and BookingService linking tables.
    String listSql = "SELECT b.BookingID, b.Status, b.StartDateTime, b.EndDateTime, " +
        "cu.FullName AS ClientName, cu.Phone AS ClientPhone, st.BusinessName, " +
        "a.Street, a.City, a.State, a.ZipCode, " +
        "(SELECT GROUP_CONCAT(p.PetName ORDER BY p.PetName SEPARATOR ', ') FROM BookingPet bp JOIN Pet p ON p.PetID=bp.PetID WHERE bp.BookingID=b.BookingID) AS Pets, " +
        "(SELECT GROUP_CONCAT(sv.ServiceName ORDER BY sv.ServiceName SEPARATOR ', ') FROM BookingService bs JOIN Service sv ON sv.ServiceID=bs.ServiceID WHERE bs.BookingID=b.BookingID) AS Services, " +
        "(SELECT SUM(bs.PriceAtBooking) FROM BookingService bs WHERE bs.BookingID=b.BookingID) AS Total, " +
        "(SELECT pm.PaymentStatus FROM Payment pm WHERE pm.BookingID=b.BookingID) AS PaymentStatus " +
        "FROM Booking b " +
        "JOIN `User` cu ON cu.UserID=b.ClientID " +
        "JOIN Sitter st ON st.UserID=b.SitterID " +
        "JOIN Address a ON a.AddressID=b.AddressID " +
        "WHERE " + (sitterUser ? "b.SitterID=?" : "b.ClientID=?") + " ORDER BY b.StartDateTime DESC";

    int bookingCount = 0;
    try (Connection c = openConnection(application)) {
        try (PreparedStatement p = c.prepareStatement(careSql)) {
            p.setInt(1, userId);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) care.computeIfAbsent(r.getInt(1), k -> new ArrayList<>())
                    .add(new String[]{r.getString(2), r.getString(3), r.getString(4), r.getString(5), r.getString(6)});
            }
        }
        try (PreparedStatement p = c.prepareStatement(listSql)) {
            p.setInt(1, userId);
            try (ResultSet r = p.executeQuery()) {
                while (r.next()) {
                    bookingCount++;
                    int id = r.getInt("BookingID");
                    String status = r.getString("Status");
                    String chip = chipClass(status);
%>
    <article class="card">
      <h3>#<%= id %> · <%= esc(r.getString("Services")) %> <span class="chip <%= chip == null ? "" : chip %>"><%= esc(label(status)) %></span></h3>
      <p class="card-meta"><%= dt(r.getString("StartDateTime")) %> to <%= dt(r.getString("EndDateTime")) %></p>
      <p>
        <% if (sitterUser) { %>Client: <strong><%= esc(r.getString("ClientName")) %></strong><% if (r.getString("ClientPhone") != null) { %> (<%= esc(r.getString("ClientPhone")) %>)<% } %><br>
        <% } else { %>Sitter: <strong><%= esc(r.getString("BusinessName")) %></strong><br><% } %>
        Pets: <%= esc(r.getString("Pets")) %><br>
        Address: <%= esc(r.getString("Street")) %>, <%= esc(r.getString("City")) %>, <%= esc(r.getString("State")) %> <%= esc(r.getString("ZipCode")) %><br>
        Service price: $<%= String.format("%.2f", r.getDouble("Total")) %> · Payment: <%= r.getString("PaymentStatus") == null ? "not recorded yet" : esc(label(r.getString("PaymentStatus"))) %>
      </p>
      <% if (care.containsKey(id)) { %>
      <details>
        <summary>Care instructions</summary>
        <% for (String[] ci : care.get(id)) { %>
          <p class="care"><strong><%= esc(ci[0]) %></strong><br>
            <% if (ci[1] != null) { %>Feeding: <%= esc(ci[1]) %><br><% } %>
            <% if (ci[2] != null) { %>Medication: <%= esc(ci[2]) %><br><% } %>
            <% if (ci[3] != null) { %>Behavior: <%= esc(ci[3]) %><br><% } %>
            <% if (ci[4] != null) { %>Emergency: <%= esc(ci[4]) %><% } %></p>
        <% } %>
      </details>
      <% } %>

      <% if (sitterUser) { %>
      <form method="post" class="card-actions inline-form">
        <input type="hidden" name="action" value="status">
        <input type="hidden" name="bookingId" value="<%= id %>">
        <label class="sr-only" for="status-<%= id %>">Status</label>
        <select id="status-<%= id %>" name="status"><%= options(BOOKING_STATUSES, status) %></select>
        <button class="btn btn-primary btn-small" type="submit">Update status</button>
      </form>
      <% } else if ("REQUESTED".equals(status) || "CONFIRMED".equals(status)) { %>
      <form method="post" class="card-actions" onsubmit="return confirm('Cancel booking #<%= id %>?');">
        <input type="hidden" name="action" value="cancel">
        <input type="hidden" name="bookingId" value="<%= id %>">
        <button class="btn btn-outline btn-small" type="submit">Cancel booking</button>
      </form>
      <% } %>
    </article>
<%
                }
            }
        }
    } catch (Exception e) { %><p class="notice notice-error"><%= esc(e.getMessage()) %></p><% }
    if (bookingCount == 0) { %><p class="muted">No bookings yet.</p><% } %>
  </div>
</main>
</div>
</body>
</html>
