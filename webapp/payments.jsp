<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/jspf/db.jspf" %>
<%
    if (!isLoggedIn(session)) { response.sendRedirect("index.jsp"); return; }
    int userId=(Integer)session.getAttribute("userId"); boolean sitterUser=isSitter(session); String message=null,error=null;
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        try (Connection c=openConnection(application)) {
            int bookingId=intParam(request.getParameter("bookingId"),0); boolean allowed=false;
            String own=sitterUser?"SELECT BookingID FROM Booking WHERE BookingID=?":"SELECT BookingID FROM Booking WHERE BookingID=? AND ClientID=?";
            try(PreparedStatement p=c.prepareStatement(own)){p.setInt(1,bookingId);if(!sitterUser)p.setInt(2,userId);try(ResultSet r=p.executeQuery()){allowed=r.next();}}
            if(!allowed) throw new Exception("You can only record payments for your own booking.");
            try(PreparedStatement p=c.prepareStatement("INSERT INTO Payment(BookingID,Amount,PaymentMethod,PaymentStatus,PaymentTime) VALUES(?,?,?,?,NOW()) ON DUPLICATE KEY UPDATE Amount=VALUES(Amount),PaymentMethod=VALUES(PaymentMethod),PaymentStatus=VALUES(PaymentStatus),PaymentTime=NOW()")){
                p.setInt(1,bookingId);p.setDouble(2,doubleParam(request.getParameter("amount"),0));p.setString(3,request.getParameter("method"));p.setString(4,request.getParameter("status"));p.executeUpdate();
            } message="Payment saved.";
        } catch(Exception e){error=e.getMessage();}
    }
%>
<!DOCTYPE html><html lang="en"><head><%@ include file="/WEB-INF/jspf/head.jspf" %><title>Payments | PetCare</title></head>
<body><%@ include file="/WEB-INF/jspf/sound.jspf" %><div class="shell"><%@ include file="/WEB-INF/jspf/sidebar.jspf" %><main class="main"><p class="crumb"><a href="dashboard.jsp">Dashboard</a></p><h1>Payments</h1>
<%if(message!=null){%><p class="notice"><%=esc(message)%></p><%}if(error!=null){%><p class="notice"><%=esc(error)%></p><%}%>
<section class="panel"><h2>Record or update a payment</h2><form method="post" class="form-grid"><label>Booking ID <input name="bookingId" type="number" min="1" required></label><label>Amount <input name="amount" type="number" min="0" step="0.01" required></label><label>Method <select name="method"><option>Cash</option><option>Credit Card</option><option>Venmo</option><option>Zelle</option></select></label><label>Status <select name="status"><option>Pending</option><option>Paid</option><option>Refunded</option></select></label><button class="btn btn-primary">Save payment</button></form></section>
<h2 class="section-title">Payment history</h2><div class="ledger"><%
String q=sitterUser?"SELECT p.*,b.ClientID,u.FullName FROM Payment p JOIN Booking b ON b.BookingID=p.BookingID JOIN `User` u ON u.UserID=b.ClientID ORDER BY p.PaymentTime DESC":"SELECT p.*,b.ClientID FROM Payment p JOIN Booking b ON b.BookingID=p.BookingID WHERE b.ClientID=? ORDER BY p.PaymentTime DESC";
try(Connection c=openConnection(application);PreparedStatement p=c.prepareStatement(q)){if(!sitterUser)p.setInt(1,userId);try(ResultSet r=p.executeQuery()){while(r.next()){%>
<article style="padding:1rem;border-bottom:1px solid #ddd"><h3>Booking #<%=r.getInt("BookingID")%></h3><p><%=sitterUser?esc(r.getString("FullName")):""%> · $<%=String.format("%.2f",r.getDouble("Amount"))%> · <%=esc(r.getString("PaymentMethod"))%> · <strong><%=esc(r.getString("PaymentStatus"))%></strong></p><p><%=r.getTimestamp("PaymentTime")%></p></article>
<%}}}catch(Exception e){%><p class="notice"><%=esc(e.getMessage())%></p><%}%></div></main></div></body></html>
