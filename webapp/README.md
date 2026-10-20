# PetCare Manager (Team 11)

The web app for PetCare Manager. The pages run on Apache Tomcat and read and write the `petcare_manager` MySQL database (the 14-table schema from our report).

## How the pieces connect

```
Browser  --->  Tomcat (the JSP pages)  --->  MySQL (petcare_manager)
 (user clicks)   (Java code runs the SQL)       (the 14 tables)
```

Each JSP page has two parts. The top part is Java: it reads the form, runs SQL with a `PreparedStatement`, and saves or loads rows. The bottom part is HTML that shows the results. The shared database code (connection, password checks, helpers) is in `WEB-INF/jspf/db.jspf`, and the login details are in `META-INF/db.properties`.

## What's in this folder

```
webapp/
├── index.jsp          Welcome page
├── start.jsp          Pick "Own a pet?" or "Wanna take care of pets?"
├── account.jsp        Sign up and log in          -> User, Client, Sitter
├── dashboard.jsp      Owner or sitter dashboard   -> Pet, Service, Booking (counts)
├── pets.jsp           Add, edit, delete pets      -> Pet
├── services.jsp       Browse or manage services   -> Service, Sitter
├── bookings.jsp       Request and manage bookings -> Booking, BookingPet, BookingService,
│                                                     CareInstruction, Address
├── payments.jsp       Record payments             -> Payment
├── table.jsp          Raw rows of one table (logged-in users only)
├── css/, js/, assets/ Styles, sound button, pictures, music
├── META-INF/
│   └── db.properties  Your MySQL login (you must edit this)
└── WEB-INF/
    ├── jspf/          Shared page pieces and the database code
    └── lib/           The MySQL driver (mysql-connector-j-26.7.0.jar), already included
```

Keep this folder structure exactly as it is. The pages find each other by path.

Every page also writes to `AuditLog` when something changes (new booking, status change, payment, service edit).

## Setup

### 1. Create the database

Run `petcare_manager.sql` in MySQL Workbench. It creates the `petcare_manager` schema with all 14 tables and the sample rows.

### 2. Put in your MySQL login

Open `META-INF/db.properties`:

```
db.url=jdbc:mysql://localhost:3306/petcare_manager?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
db.user=root
db.password=change_me
```

- Replace `change_me` with your MySQL password (the one you use in Workbench).
- Change `root` only if you log in to MySQL with a different user.
- Change `petcare_manager` only if your schema has a different name.

**Do not upload your real password to GitHub.** Change it back to `change_me` before you commit.

### 3. Run it on Tomcat (pick one)

**Option A: Tomcat on its own (no Eclipse)**

1. Copy the whole `webapp` folder into Tomcat's `webapps` folder and rename it `petcare`. You should end up with `<tomcat>/webapps/petcare/index.jsp`.
2. Start (or restart) Tomcat.
3. Open http://localhost:8080/petcare/

**Option B: Eclipse**

1. Copy everything inside `webapp/` into your project's `src/main/webapp/` folder.
2. Right-click the project > Properties > Targeted Runtimes > check your Apache Tomcat > Apply.
3. Right-click the project > Run As > Run on Server.
4. Open `http://localhost:8080/<your-project-name>/`

## Try it with the sample data

Every sample user's password is `pw_` plus their first name in lowercase.

| Who | Email | Password | Log in from |
|---|---|---|---|
| Pet owner | emily.carter@gmail.com | pw_emily | "Own a pet?" |
| Pet sitter | maria@pawsitivecare.com | pw_maria | "Wanna take care of pets?" |

Ryan Patel is suspended in the sample data, so his login is refused on purpose.

A demo walk-through: log in as Emily, request a booking for Biscuit with Maria's "Dog Walk (30 min)", then log out, log in as Maria, and confirm it on the bookings page. Check `Booking`, `BookingPet`, `BookingService`, and `AuditLog` in Workbench to see the new rows.

## Good to know

- **Passwords:** new accounts are saved with a salted PBKDF2 hash. The sample rows use `SHA2('pw_name',256)`, and the login page accepts both.
- **Bookings:** a booking saves one `Booking` row, one `BookingPet` row per pet, a `BookingService` row with `PriceAtBooking`, and a `CareInstruction` row per pet if you typed instructions. All of these save together, or none do.
- **Rules the booking page checks:** the pets must be yours, the service must be available, the end time must be after the start, a pet can't be in two active bookings at once, and a service can't have more overlapping active bookings than its `Capacity`.
- **Who can do what:** owners manage only their own pets, bookings, and payments. Sitters manage only their own services, and only the bookings and payments assigned to them. The logged-in user's ID always comes from the session, never from the URL.
- **Dates and times** are read and written exactly as stored in MySQL, so they match what you see in Workbench.
- **Sound:** the button in the top right turns the music on and off. Browsers block sound until you click something on the page.
- **Fonts** load from the internet. Offline, the pages still work but look a little plainer.

## Troubleshooting

| What you see | What to do |
|---|---|
| HTTP 404 | Open `localhost:8080/petcare/` (Option A) or `localhost:8080/<your-project-name>/` (Option B), not plain `localhost:8080/`. |
| "MySQL rejected the username or password" | Fix `db.user` or `db.password` in `META-INF/db.properties`. |
| "The database name in db.url does not exist" | The schema name in `db.url` is wrong. Copy it exactly from MySQL Workbench. |
| "Tomcat could not reach MySQL" | Start the MySQL server and check the port in `db.url` (usually 3306). |
| "The MySQL driver is missing" | Make sure `WEB-INF/lib/mysql-connector-j-26.7.0.jar` is there, then restart Tomcat. |
| "Unknown column ..." on a page | Your tables don't match `petcare_manager.sql`. Re-run that script. |
| Changes don't show up | Restart Tomcat and refresh the browser with Ctrl+F5. |
