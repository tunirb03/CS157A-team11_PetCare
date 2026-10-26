# PetCare Manager

CS157A Team 11 project.

PetCare Manager is a web app for a small pet-sitting business. Pet owners can save their pets, book services, pay for bookings, and review the care they got. The sitter can manage services, bookings, payments, and reviews in one place, without paying a marketplace app a cut of every booking.

## Team

- Yi Xiao
- Tunir Bhattacharya

## Built with

- Java and JSP, running on Apache Tomcat 10 or newer
- MySQL 8
- MySQL Connector/J (already included in `webapp/WEB-INF/lib`)

## Functional requirements

| # | Requirement | What the app does | Page |
|---|---|---|---|
| FR1 | Account management | Users sign up and log in as either a pet owner or a pet sitter. Passwords are stored as salted PBKDF2 hashes. | `start.jsp`, `account.jsp` |
| FR2 | Pet management | Owners add, edit, and delete their own pets. A pet that has bookings cannot be deleted. | `pets.jsp` |
| FR3 | Service management | Sitters add and edit services and mark them available or unavailable. Owners browse the available services. | `services.jsp` |
| FR4 | Booking management | Owners request a booking for one or more pets, with care instructions, and can cancel while it is requested or confirmed. Sitters confirm, decline, start, complete, or cancel bookings. Capacity and double-booking are checked. | `bookings.jsp` |
| FR5 | Payment management | Owners and sitters record and view payments for their bookings (cash, credit card, Venmo, or Zelle; pending, paid, or refunded). A summary shows the totals. | `payments.jsp` |
| FR6 | Review management | After a booking is completed, the owner leaves a 1 to 5 star rating, an optional comment, and an optional tip. The sitter sees the reviews, the average rating, and the tips. | `reviews.jsp` |

Rules built into the pages:

- A payment can be recorded only after the sitter has confirmed the booking. Each booking has one payment, and saving again updates it.
- Choosing a booking on the payments page fills in its service price. Change the amount if the final total is different, for example for several nights.
- A booking can be reviewed once, and only after it is completed.
- New bookings, status changes, service changes, payments, and reviews are saved to the `audit_log` table.

## Project layout

```
CS157A-team11_PetCare/
  petcare_DB.sql         Creates the database, tables, and sample rows
  Team11_*.pdf           Project proposal and database design document
  webapp/
    index.jsp            Welcome page
    start.jsp            Choose pet owner or pet sitter
    account.jsp          Sign up and log in (FR1)
    dashboard.jsp        Dashboard for owners and sitters
    pets.jsp             Manage pets, owners only (FR2)
    services.jsp         Browse or manage services (FR3)
    bookings.jsp         Request and manage bookings (FR4)
    payments.jsp         Record and view payments (FR5)
    reviews.jsp          Leave and view reviews (FR6)
    table.jsp            Shows the raw rows of one table (logged-in users only)
    css/ js/ assets/     Styles, sound button, images, and music
    META-INF/            db.properties (MySQL connection settings)
    WEB-INF/jspf/        Shared page parts and database code (db.jspf)
    WEB-INF/lib/         MySQL driver
```

## How to run it

### 1. Create the database

Open `petcare_DB.sql` in MySQL Workbench and run the whole file. It creates the `petcare_manager` database with 14 tables and fills it with sample data. Running it again deletes everything in those tables, including accounts you made in the app, and restores the sample data.

### 2. Add your MySQL login

Open `webapp/META-INF/db.properties` and fill in your own details:

```
db.url=jdbc:mysql://localhost:3306/petcare_manager?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
db.user=root
db.password=your_mysql_password
```

Do not push your real password to GitHub. Change it back to `CHANGE_ME` before you commit.

If you use a separate MySQL user instead of `root`, give it access to the new database (run this as an admin account):

```sql
GRANT ALL PRIVILEGES ON petcare_manager.* TO 'your_user'@'localhost';
FLUSH PRIVILEGES;
```

### 3. Run it on Tomcat

**Option A: Tomcat by itself**

1. Copy the `webapp` folder into Tomcat's `webapps` folder and rename it to `petcare`.
2. Start Tomcat.
3. Open http://localhost:8080/petcare/

**Option B: Eclipse**

1. Copy everything inside `webapp/` into your project's `src/main/webapp/` folder.
2. Right-click the project > Properties > Targeted Runtimes, check Apache Tomcat, and click Apply.
3. Right-click the project > Run As > Run on Server.
4. Open `http://localhost:8080/<your-project-name>/`

### 4. Make an account

The sample users in `petcare_DB.sql` have placeholder passwords, so they cannot log in. Create a new account in the app instead:

- Pick **"Own a pet?"** to make a pet owner account.
- Pick **"Wanna take care of pets?"** to make a pet sitter account.

## Try the whole flow

1. Sign up as a **sitter** and add a service on **Manage services**.
2. Sign up as an **owner** (use a different email, or a second browser or private window), add a pet on **My pets**, then open **Browse services** and click **Book this**.
3. Back in the sitter account, open **Manage bookings** and set the booking to **Confirmed**, then later to **Completed**.
4. In either account, open **Payments**, pick the booking, and save a payment.
5. In the owner account, open **My reviews**, rate the completed booking, and add a tip.
6. In MySQL Workbench, run `SELECT * FROM audit_log ORDER BY LogID DESC;` to see every step recorded.

## Troubleshooting

| Problem | What to do |
|---|---|
| 404 page | Include the app name in the address, like `localhost:8080/petcare/` |
| "MySQL rejected the username or password" | Check `db.user` and `db.password` in `db.properties` |
| "Access denied for user ... to database 'petcare_manager'" | The user exists but has no rights on this database. Run the `GRANT` from step 2. |
| "The database name in db.url does not exist" | Make sure `db.url` ends in `/petcare_manager?...` and that you ran `petcare_DB.sql` |
| "Unknown column ..." or "Table ... doesn't exist" | The app is connected to an older database. Check `db.url`, or run the current `petcare_DB.sql` again. |
| "Payments can be recorded after the sitter confirms the booking." | Log in as the sitter and set the booking to Confirmed first |
| "Tomcat could not reach MySQL" | Start the MySQL server and check the port (usually 3306) |
| Errors that mention `jakarta` | Use Tomcat 10 or newer. Tomcat 9 will not work. |
| Changes don't show up | Restart Tomcat and hard refresh the browser (Ctrl+F5) |

Note for Linux: MySQL table names are case-sensitive there by default. The pages and `petcare_DB.sql` use the same names except for capitalization (for example `Booking` and `booking`), which MySQL accepts by default on Windows and macOS. On Linux you may need to set `lower_case_table_names=1` before creating the database.
