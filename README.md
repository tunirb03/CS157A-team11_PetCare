# PetCare Manager

CS157A Team 11 project.

PetCare Manager is a web app for a small pet-sitting business. Pet owners can save their pets, book services, and keep track of payments. The sitter can manage services, bookings, and payments in one place, without paying a marketplace app a cut of every booking.

## Team

- Yi Xiao
- Tunir Bhattacharya

## Built with

- Java and JSP, running on Apache Tomcat 10 or newer
- MySQL 8
- MySQL Connector/J (already included in `webapp/WEB-INF/lib`)

## What it does

Pet owners can:

- Sign up and log in
- Add, edit, and delete their pets
- Browse the available services
- Request a booking for one or more pets, with care instructions
- Cancel a booking while it is still requested or confirmed
- Record and view payments for their bookings

Pet sitters can:

- Sign up and log in
- Add and edit their services, and mark them available or unavailable
- Change a booking's status (confirm, decline, in progress, complete, cancel)
- Record and view payments for their bookings

New bookings, status changes, payments, and service changes are also saved to the `AuditLog` table.

## Project layout

```
CS157A-team11_PetCare/
  schema.sql             Creates the database, tables, and sample rows
  Team11_*.pdf           Project proposal and database design document
  webapp/
    index.jsp            Welcome page
    start.jsp            Choose pet owner or pet sitter
    account.jsp          Sign up and log in
    dashboard.jsp        Dashboard for owners and sitters
    pets.jsp             Manage pets (owners only)
    services.jsp         Browse or manage services
    bookings.jsp         Request and manage bookings
    payments.jsp         Record and view payments
    table.jsp            Shows the raw rows of one table (logged-in users only)
    css/ js/ assets/     Styles, sound button, images, and music
    META-INF/            db.properties (MySQL connection settings)
    WEB-INF/jspf/        Shared page parts and database code
    WEB-INF/lib/         MySQL driver
```

## How to run it

### 1. Create the database

Open `schema.sql` in MySQL Workbench and run it. It creates the `petcare_model` database and fills it with sample data.

### 2. Add your MySQL login

Open `webapp/META-INF/db.properties` and fill in your own details:

```
db.url=jdbc:mysql://localhost:3306/petcare_model?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
db.user=root
db.password=your_mysql_password
```

Do not push your real password to GitHub. Change it back to `CHANGE_ME` before you commit.

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

The sample users in `schema.sql` have placeholder passwords, so they cannot log in. Create a new account in the app instead:

- Pick **"Own a pet?"** to make a pet owner account.
- Pick **"Wanna take care of pets?"** to make a pet sitter account.

## Troubleshooting

| Problem | What to do |
|---|---|
| 404 page | Include the app name in the address, like `localhost:8080/petcare/` |
| "MySQL rejected the username or password" | Check `db.user` and `db.password` in `db.properties` |
| "The database name in db.url does not exist" | Make sure `db.url` ends in `/petcare_model?...` |
| "Tomcat could not reach MySQL" | Start the MySQL server and check the port (usually 3306) |
| Errors that mention `jakarta` | Use Tomcat 10 or newer. Tomcat 9 will not work. |
| Changes don't show up | Restart Tomcat and hard refresh the browser (Ctrl+F5) |
