<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    int userId = (Integer) session.getAttribute("userId"); boolean sitterUser = isSitter(session);
    List<String> tables = new ArrayList<>(); String current = null;
    String message = null, error = null;
    try (Connection conn = openConnection(application)) {
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String action = request.getParameter("action"); int bookingId = intParam(request.getParameter("bookingId"), 0);
            if ("status".equals(action) && (sitterUser || "CANCELLED".equals(request.getParameter("status")))) {
                String sql = sitterUser ? "UPDATE Booking SET Status=? WHERE BookingID=?" : "UPDATE Booking SET Status='CANCELLED' WHERE BookingID=? AND ClientID=?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    if (sitterUser) { ps.setString(1, request.getParameter("status")); ps.setInt(2, bookingId); }
                    else { ps.setInt(1, bookingId); ps.setInt(2, userId); }
                    ps.executeUpdate();
                } message = "Booking status updated.";
            } else if ("create".equals(action) && !sitterUser) {
                int serviceId = intParam(request.getParameter("serviceId"), 0); int petId = intParam(request.getParameter("petId"), 0);
                Timestamp start = Timestamp.valueOf(request.getParameter("startTime").replace('T', ' ') + ":00");
                Timestamp end = Timestamp.valueOf(request.getParameter("endTime").replace('T', ' ') + ":00");
                if (!end.after(start)) throw new Exception("The end time must be after the start time.");
                try (PreparedStatement own = conn.prepareStatement("SELECT PetID FROM Pet WHERE PetID=? AND OwnerID=?")) { own.setInt(1, petId); own.setInt(2, userId); try (ResultSet r = own.executeQuery()) { if (!r.next()) throw new Exception("Please select one of your own pets."); } }
                try (PreparedStatement overlap = conn.prepareStatement("SELECT COUNT(*) FROM Booking WHERE Status NOT IN ('CANCELLED','DECLINED','COMPLETED') AND StartDateTime < ? AND EndDateTime > ?")) {
                    overlap.setTimestamp(1, end); overlap.setTimestamp(2, start); try (ResultSet r = overlap.executeQuery()) { r.next(); if (r.getInt(1) > 0) throw new Exception("That time overlaps an existing booking."); }
                }
                double price;
                try (PreparedStatement sp = conn.prepareStatement("SELECT Price FROM Service WHERE ServiceID=? AND AvailabilityStatus='AVAILABLE'")) { sp.setInt(1, serviceId); try (ResultSet r = sp.executeQuery()) { if (!r.next()) throw new Exception("That service is not available."); price = r.getDouble(1); } }
                conn.setAutoCommit(false);
                try (PreparedStatement bp = conn.prepareStatement("INSERT INTO Booking(ClientID,SitterID,StartDateTime,EndDateTime,Status) VALUES(?,(SELECT UserID FROM Sitter ORDER BY UserID LIMIT 1),?,?, 'REQUESTED')", Statement.RETURN_GENERATED_KEYS)) {
                    bp.setInt(1, userId); bp.setTimestamp(2, start); bp.setTimestamp(3, end);
                    bp.executeUpdate(); try (ResultSet keys = bp.getGeneratedKeys()) { keys.next(); int newId = keys.getInt(1);
                        try (PreparedStatement join = conn.prepareStatement("INSERT INTO BookingPet(BookingID,PetID) VALUES(?,?)")) { join.setInt(1, newId); join.setInt(2, petId); join.executeUpdate(); }
                        try (PreparedStatement join = conn.prepareStatement("INSERT INTO BookingService(BookingID,ServiceID,PriceAtBooking) VALUES(?,?,?)")) { join.setInt(1, newId); join.setInt(2, serviceId); join.setDouble(3, price); join.executeUpdate(); }
                    }
                }
                conn.commit(); conn.setAutoCommit(true); message = "Booking request submitted.";
            }
        }
    } catch (Exception e) { error = e.getMessage(); }
%>
<!DOCTYPE html><html lang="en"><head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Bookings | PetCare</title></head>
<body><%@ include file="/WEB-INF/jspf/sound.jspf" %><div class="shell"><%@ include file="/WEB-INF/jspf/sidebar.jspf" %><main class="main"><p class="crumb"><a href="dashboard.jsp">Dashboard</a></p><h1><%= sitterUser ? "Manage bookings" : "My bookings" %></h1>
<% if (message != null) { %><p class="notice"><%= esc(message) %></p><% } %><% if (error != null) { %><p class="notice"><%= esc(error) %></p><% } %>
<% if (!sitterUser) { %><section class="panel"><h2>Request a booking</h2><form method="post" class="form-grid"><input type="hidden" name="action" value="create"><label>Pet <select name="petId" required><option value="">Choose a pet</option><% try (Connection c=openConnection(application); PreparedStatement p=c.prepareStatement("SELECT PetID,PetName FROM Pet WHERE OwnerID=? ORDER BY PetName")) { p.setInt(1,userId); try(ResultSet r=p.executeQuery()){while(r.next()){%><option value="<%=r.getInt("PetID")%>"><%=esc(r.getString("PetName"))%></option><%}}} %></select></label><label>Service <select name="serviceId" required><option value="">Choose a service</option><% try (Connection c=openConnection(application); PreparedStatement p=c.prepareStatement("SELECT ServiceID,ServiceName,Price FROM Service WHERE AvailabilityStatus='AVAILABLE' ORDER BY ServiceName")) { try(ResultSet r=p.executeQuery()){while(r.next()){%><option value="<%=r.getInt("ServiceID")%>"><%=esc(r.getString("ServiceName"))%> ($<%=String.format("%.2f",r.getDouble("Price"))%>)</option><%}}} %></select></label><label>Start <input name="startTime" type="datetime-local" required></label><label>End <input name="endTime" type="datetime-local" required></label><label>Address <input name="address"></label><label>Special instructions <textarea name="instructions"></textarea></label><button class="btn btn-primary">Request booking</button></form></section><% } %>
<h2 class="section-title">Booking history</h2><div class="ledger"><%
String q = sitterUser ? "SELECT b.*,u.FullName, s.ServiceName service_name, (SELECT COALESCE(SUM(bs2.PriceAtBooking),0) FROM BookingService bs2 WHERE bs2.BookingID=b.BookingID) total_price FROM Booking b JOIN `User` u ON u.UserID=b.ClientID JOIN BookingService bs ON bs.BookingID=b.BookingID JOIN Service s ON s.ServiceID=bs.ServiceID WHERE bs.ServiceID=(SELECT MIN(bs3.ServiceID) FROM BookingService bs3 WHERE bs3.BookingID=b.BookingID) ORDER BY b.StartDateTime DESC" : "SELECT b.*,s.ServiceName service_name, (SELECT COALESCE(SUM(bs2.PriceAtBooking),0) FROM BookingService bs2 WHERE bs2.BookingID=b.BookingID) total_price FROM Booking b JOIN BookingService bs ON bs.BookingID=b.BookingID JOIN Service s ON s.ServiceID=bs.ServiceID WHERE b.ClientID=? AND bs.ServiceID=(SELECT MIN(bs3.ServiceID) FROM BookingService bs3 WHERE bs3.BookingID=b.BookingID) ORDER BY b.StartDateTime DESC";
try (Connection c=openConnection(application); PreparedStatement p=c.prepareStatement(q)) { if(!sitterUser)p.setInt(1,userId); try(ResultSet r=p.executeQuery()){while(r.next()){%>
<article style="padding:1rem;border-bottom:1px solid #ddd"><h3>#<%=r.getInt("BookingID")%> — <%=esc(r.getString("service_name"))%></h3><p><%=sitterUser?esc(r.getString("FullName")):""%> <%=r.getTimestamp("StartDateTime")%> to <%=r.getTimestamp("EndDateTime")%></p><p>Status: <strong><%=esc(r.getString("Status"))%></strong> · Estimated price: $<%=String.format("%.2f",r.getDouble("total_price"))%></p>
<% if (sitterUser) { %><form method="post"><input type="hidden" name="action" value="status"><input type="hidden" name="bookingId" value="<%=r.getInt("BookingID")%>"><select name="status"><option>REQUESTED</option><option>CONFIRMED</option><option>IN PROGRESS</option><option>COMPLETED</option><option>CANCELLED</option><option>DECLINED</option></select><button class="btn btn-primary">Update status</button></form><% } else if (!"CANCELLED".equals(r.getString("Status")) && !"COMPLETED".equals(r.getString("Status"))) { %><form method="post"><input type="hidden" name="action" value="status"><input type="hidden" name="bookingId" value="<%=r.getInt("BookingID")%>"><input type="hidden" name="status" value="CANCELLED"><button class="btn btn-outline">Cancel booking</button></form><% } %></article>
<%}}} catch(Exception e){%><p class="notice"><%=esc(e.getMessage())%></p><%}%></div></main></div></body></html>
