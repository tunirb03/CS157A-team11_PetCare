# PetCare Manager: Frontend

The web pages for PetCare Manager (Team 11). They run on Apache Tomcat and read data from a MySQL database.

## What's in this repo

```
src/main/webapp/
├── index.jsp          Welcome page ("welcome to petcare!")
├── start.jsp          Pick "Own a pet?" or "Wanna take care of pets?"
├── account.jsp        Sign-up and log-in form
├── dashboard.jsp      Dashboard with your pets and database tables
├── table.jsp          Shows the rows of one table
├── css/               Page styles
├── js/sound.js        The sound on/off button
├── assets/img/        Pictures (dog, cat, girl, snake)
├── assets/sound/      Background music
└── WEB-INF/
    ├── db.properties  Your MySQL login (you must edit this)
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

### 3. Change the schema name and password

Open `src/main/webapp/WEB-INF/db.properties`. It looks like this:

```
db.url=jdbc:mysql://localhost:3306/petcare?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
db.user=root
db.password=change_me
```

Change three things:

- **Schema name:** replace `petcare` in `db.url` with your schema name. This is the name shown under "Schemas" in MySQL Workbench. Only change that one word.
- **Username:** replace `root` if you log in to MySQL with a different user.
- **Password:** replace `change_me` with your MySQL password.

If your MySQL server uses a port other than 3306, change `3306` too.

**Do not upload your real password to GitHub.** Before you commit, change the password back to `change_me`.

### 4. Tell Eclipse which Tomcat to use

Right-click your project > Properties > Targeted Runtimes > check your Apache Tomcat > Apply. This also clears most red error marks on JSP files.

### 5. Run it

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
4. **Dashboard:** a yellow tag saying "Connected to" your schema name, a list of your pets, and a list of your tables with row counts. Click a table to see its rows.

## Good to know

- **Login is not checked yet.** The form does not save accounts or check passwords. Submitting it just opens the dashboard for now.
- **The pets list reads a table named `Pet`** (or `pets`). It shows each pet's name, plus species and breed if those columns exist. If there is no Pet table yet, the box says "No pets yet."
- **Sound:** the button in the top right turns the music on and off. It remembers your choice between pages. Browsers block sound until you click something on the page, so the music may start on your first click.
- **Fonts** load from the internet. Offline, the pages still work but look a little plainer.
- **Tables are read straight from MySQL.** You don't need to edit any code when you add new tables. Just refresh the page.

## Troubleshooting

| What you see | What to do |
|---|---|
| HTTP 404 at `localhost:8080/` | Open `localhost:8080/<your-project-name>/` instead, or set the context root to `/` (see step 5). |
| 404 at your project address too | Make sure `index.jsp` is directly inside `src/main/webapp/`, and that your project is listed under the Tomcat server in the Servers tab. |
| "The MySQL driver is missing" | The jar is not in `WEB-INF/lib/`. Add it and restart Tomcat. |
| "MySQL rejected the username or password" | Fix `db.user` or `db.password` in `db.properties`. |
| "The database name in db.url does not exist" | The schema name in `db.url` is wrong. Copy it exactly from MySQL Workbench. |
| "Tomcat could not reach MySQL" | Start the MySQL server and check the port in `db.url`. |
| Red error marks on JSP files | Set the Targeted Runtime to your Tomcat (step 4). |
| Changes don't show up | Restart Tomcat and refresh the browser with Ctrl+F5. |
