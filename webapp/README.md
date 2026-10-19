# PetCare Manager: Frontend

The web pages for PetCare Manager (Team 11). They run on Apache Tomcat and read data from a MySQL database.

## What's in this repo

```
src/main/webapp/
├── index.jsp          Welcome page ("welcome to petcare!")
├── start.jsp          Pick "Own a pet?" or "Wanna take care of pets?"
├── account.jsp        Sign-up and log-in form
├── dashboard.jsp      Role-specific owner or sitter dashboard
├── table.jsp          Shows the rows of one table
├── pets.jsp           Add, edit, and delete pet profiles
├── services.jsp       Service directory and sitter service management
├── bookings.jsp       Booking requests and sitter status management
├── payments.jsp       Payment records and payment history
├── css/               Page styles
├── js/sound.js        The sound on/off button
├── assets/img/        Pictures (dog, cat, girl, snake)
├── assets/sound/      Background music
├── META-INF/
│   └── db.properties  Your MySQL login (you must edit this)
└── WEB-INF/
    └── jspf/          Shared page pieces and the database code
```

Keep this folder structure exactly as it is. The pages find each other by path.

## What you need

- Eclipse IDE for Enterprise Java and Web Developers
- Apache Tomcat 11 (Tomcat 10 also works)
- Java 17 or newer
- MySQL Server and MySQL Workbench
- The MySQL driver: `mysql-connector-j-<version>.jar`
  (download from https://dev.mysql.com/downloads/connector/j/, choose "Platform Independent")

## Setup

### 1. Copy the files into your project

Copy everything inside `src/main/webapp/` into your Eclipse project's `src/main/webapp/` folder. Your own files there (like other JSP pages, `META-INF`, and `web.xml`) can stay.

### 2. Add the MySQL driver

Put the `mysql-connector-j` jar file in `src/main/webapp/WEB-INF/lib/`. Create the `lib` folder if it doesn't exist.

Tomcat only loads jars from this folder. Adding the jar to the Eclipse Build Path is not enough.

### 3. Create the PetCare tables

Open `schema.sql` in MySQL Workbench and run it. It creates the `petcare_model`
database and the 12 entity tables represented in the data model: `User`,
`Client`, `Sitter`, `Address`, `Pet`, `Service`, `Booking`,
`CareInstruction`, `Payment`, `Review`, `CareEvent`, and `AuditLog`.
The script also inserts demonstration data for screenshots.

### 4. Change the schema name and password

Open `src/main/webapp/META-INF/db.properties`. It looks like this:

```
db.url=jdbc:mysql://localhost:3306/petcare14?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
db.user=petcare_user
db.password=YOUR_MYSQL_USER_PASSWORD
```

Change three things:

- **Schema name:** use `petcare_model` or the schema where you ran the new script.
- **Username:** use the MySQL account that has access to that schema.
- **Password:** use that MySQL account's password.

If your MySQL server uses a port other than 3306, change `3306` too.

**Do not upload your real password to GitHub.** Before you commit, change the password back to `change_me`.

### 5. Tell Eclipse which Tomcat to use

Right-click your project > Properties > Targeted Runtimes > check your Apache Tomcat > Apply. This also clears most red error marks on JSP files.

### 6. Run it

Right-click your project > Run As > Run on Server. Then open:

```
http://localhost:8080/<your-project-name>/
```

Replace `<your-project-name>` with your Eclipse project's name. Plain `http://localhost:8080/` will show a 404 unless you change the context root (see below).

**Optional:** to open the site at plain `http://localhost:8080/`, go to Properties > Web Project Settings, set Context root to `/`, and click Apply. Then in the Servers tab, remove the project from Tomcat, add it back, and restart the server.

## What you should see

1. **Welcome page:** the title, a faded picture, and two buttons: Get started and Log in.
2. **Choice page:** a dog ("Own a pet?") and a cat ("Wanna take care of pets?").
3. **Form page:** sign up or log in, with the snake picture.
4. **Dashboard:** owners see pet, service, booking, and payment actions; sitters see service, booking, and payment management actions. The page no longer exposes every database table as the main user interface.

## Good to know

- **Authentication:** registration saves a `User` plus a `Client` or `Sitter` subclass account. Login checks a PBKDF2 password hash and creates a session.
- **Pet profiles:** clients can add, edit, delete, and view their own pets.
- **Services:** clients can view active services; sitters can add, edit, and deactivate services.
- **Bookings:** clients can request a booking and cancel it. The sitter can update booking status. Overlapping active bookings are rejected.
- **Payments:** clients and sitters can record payment method, amount, and status. A booking has at most one payment record.
- **Role separation:** owners can manage only their own pets and bookings; sitters can manage only their own services and assigned bookings.
- **Sound:** the button in the top right turns the music on and off. It remembers your choice between pages. Browsers block sound until you click something on the page, so the music may start on your first click.
- **Fonts** load from the internet. Offline, the pages still work but look a little plainer.

## Troubleshooting

| What you see | What to do |
|---|---|
| HTTP 404 at `localhost:8080/` | Open `localhost:8080/<your-project-name>/` instead, or set the context root to `/` (see step 5). |
| 404 at your project address too | Make sure `index.jsp` is directly inside `src/main/webapp/`, and that your project is listed under the Tomcat server in the Servers tab. |
| "The MySQL driver is missing" | The jar is not in `WEB-INF/lib/`. Add it and restart Tomcat. |
| "MySQL rejected the username or password" | Fix `db.user` or `db.password` in `META-INF/db.properties`. |
| "The database name in db.url does not exist" | The schema name in `db.url` is wrong. Copy it exactly from MySQL Workbench. |
| "Tomcat could not reach MySQL" | Start the MySQL server and check the port in `db.url`. |
| Red error marks on JSP files | Set the Targeted Runtime to your Tomcat (step 4). |
| Changes don't show up | Restart Tomcat and refresh the browser with Ctrl+F5. |
