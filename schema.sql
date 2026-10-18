CREATE DATABASE IF NOT EXISTS petcare;
USE petcare;

-- The proposal requires these 14 tables:
-- User, Client, Sitter, Address, Pet, Service, Booking, BookingPet,
-- BookingService, CareInstruction, Payment, Review, CareEvent, AuditLog.

CREATE TABLE IF NOT EXISTS `User` (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Email VARCHAR(150) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Phone VARCHAR(30),
    AccountStatus ENUM('ACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Client (
    UserID INT PRIMARY KEY,
    EmergencyContactName VARCHAR(100),
    EmergencyContactPhone VARCHAR(30),
    FOREIGN KEY (UserID) REFERENCES `User`(UserID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Sitter (
    UserID INT PRIMARY KEY,
    BusinessName VARCHAR(150) NOT NULL,
    Bio TEXT,
    ServiceArea VARCHAR(150),
    FOREIGN KEY (UserID) REFERENCES `User`(UserID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Address (
    AddressID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    Street VARCHAR(150) NOT NULL,
    City VARCHAR(80) NOT NULL,
    State VARCHAR(30) NOT NULL,
    ZipCode VARCHAR(15) NOT NULL,
    AddressType VARCHAR(30) DEFAULT 'Home',
    FOREIGN KEY (UserID) REFERENCES `User`(UserID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Pet (
    PetID INT PRIMARY KEY AUTO_INCREMENT,
    OwnerID INT NOT NULL,
    PetName VARCHAR(100) NOT NULL,
    Species VARCHAR(50) NOT NULL,
    Breed VARCHAR(100),
    Age INT,
    Gender VARCHAR(30),
    Color VARCHAR(80),
    Markings VARCHAR(255),
    FavoriteToys VARCHAR(255),
    EmergencyNotes TEXT,
    PhotoURL VARCHAR(255),
    FeedingInstructions TEXT,
    MedicationNeeds TEXT,
    BehavioralNotes TEXT,
    FOREIGN KEY (OwnerID) REFERENCES Client(UserID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Service (
    ServiceID INT PRIMARY KEY AUTO_INCREMENT,
    SitterID INT NOT NULL,
    ServiceName VARCHAR(100) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Description TEXT,
    Price DECIMAL(10,2) NOT NULL,
    DurationMinutes INT NOT NULL,
    Capacity INT NOT NULL DEFAULT 1,
    AvailabilityStatus ENUM('AVAILABLE','UNAVAILABLE') NOT NULL DEFAULT 'AVAILABLE',
    FOREIGN KEY (SitterID) REFERENCES Sitter(UserID)
);

CREATE TABLE IF NOT EXISTS Booking (
    BookingID INT PRIMARY KEY AUTO_INCREMENT,
    ClientID INT NOT NULL,
    SitterID INT NOT NULL,
    AddressID INT,
    StartDateTime DATETIME NOT NULL,
    EndDateTime DATETIME NOT NULL,
    Status ENUM('REQUESTED','CONFIRMED','IN PROGRESS','COMPLETED','CANCELLED','DECLINED') NOT NULL DEFAULT 'REQUESTED',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ClientID) REFERENCES Client(UserID),
    FOREIGN KEY (SitterID) REFERENCES Sitter(UserID),
    FOREIGN KEY (AddressID) REFERENCES Address(AddressID),
    CHECK (EndDateTime > StartDateTime)
);

CREATE TABLE IF NOT EXISTS BookingPet (
    BookingID INT NOT NULL,
    PetID INT NOT NULL,
    PRIMARY KEY (BookingID, PetID),
    FOREIGN KEY (BookingID) REFERENCES Booking(BookingID) ON DELETE CASCADE,
    FOREIGN KEY (PetID) REFERENCES Pet(PetID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS BookingService (
    BookingID INT NOT NULL,
    ServiceID INT NOT NULL,
    PriceAtBooking DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (BookingID, ServiceID),
    FOREIGN KEY (BookingID) REFERENCES Booking(BookingID) ON DELETE CASCADE,
    FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)
);

CREATE TABLE IF NOT EXISTS CareInstruction (
    InstructionID INT PRIMARY KEY AUTO_INCREMENT,
    BookingID INT NOT NULL,
    PetID INT NOT NULL,
    FeedingInstructions TEXT,
    MedicationNeeds TEXT,
    BehavioralNotes TEXT,
    EmergencyNotes TEXT,
    UNIQUE (BookingID, PetID),
    FOREIGN KEY (BookingID, PetID) REFERENCES BookingPet(BookingID, PetID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Payment (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT,
    BookingID INT NOT NULL UNIQUE,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod ENUM('Cash','Credit Card','Venmo','Zelle') NOT NULL,
    PaymentStatus ENUM('Pending','Paid','Refunded') NOT NULL DEFAULT 'Pending',
    PaymentTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (BookingID) REFERENCES Booking(BookingID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Review (
    ReviewID INT PRIMARY KEY AUTO_INCREMENT,
    BookingID INT NOT NULL UNIQUE,
    ClientID INT NOT NULL,
    Rating INT NOT NULL,
    Comment TEXT,
    TipAmount DECIMAL(10,2) DEFAULT 0,
    ReviewDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (BookingID) REFERENCES Booking(BookingID) ON DELETE CASCADE,
    FOREIGN KEY (ClientID) REFERENCES Client(UserID),
    CHECK (Rating BETWEEN 1 AND 5)
);

CREATE TABLE IF NOT EXISTS CareEvent (
    EventID INT PRIMARY KEY AUTO_INCREMENT,
    BookingID INT NOT NULL,
    PetID INT NOT NULL,
    EventType ENUM('DropOff','PickUp') NOT NULL,
    EventTime DATETIME NOT NULL,
    FOREIGN KEY (BookingID, PetID) REFERENCES BookingPet(BookingID, PetID) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS AuditLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    Action VARCHAR(80) NOT NULL,
    Description TEXT,
    ActionTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (UserID) REFERENCES `User`(UserID)
);

-- Demonstration data: ten rows for each table. The sample passwords are
-- placeholders for database screenshots; create a new account in the app
-- to test login because the app creates a real password hash.
INSERT IGNORE INTO `User`(UserID,Email,PasswordHash,FullName,Phone) VALUES
(1,'alex@example.com','sample-hash','Alex Chen','555-0101'),(2,'bianca@example.com','sample-hash','Bianca Lee','555-0102'),
(3,'carlos@example.com','sample-hash','Carlos Rivera','555-0103'),(4,'diana@example.com','sample-hash','Diana Patel','555-0104'),
(5,'elena@example.com','sample-hash','Elena Kim','555-0105'),(6,'frank@example.com','sample-hash','Frank Wong','555-0106'),
(7,'grace@example.com','sample-hash','Grace Smith','555-0107'),(8,'henry@example.com','sample-hash','Henry Davis','555-0108'),
(9,'isabel@example.com','sample-hash','Isabel Garcia','555-0109'),(10,'jordan@example.com','sample-hash','Jordan Brown','555-0110'),
(11,'sitter@petcare.com','sample-hash','Yi Xiao','555-0111'),(12,'sitter2@petcare.com','sample-hash','Noah Park','555-0112'),
(13,'sitter3@petcare.com','sample-hash','Olivia Nguyen','555-0113'),(14,'sitter4@petcare.com','sample-hash','Peter Hall','555-0114'),
(15,'sitter5@petcare.com','sample-hash','Quinn Adams','555-0115'),(16,'sitter6@petcare.com','sample-hash','Riley Wilson','555-0116'),
(17,'sitter7@petcare.com','sample-hash','Sofia Moore','555-0117'),(18,'sitter8@petcare.com','sample-hash','Theo Martin','555-0118'),
(19,'sitter9@petcare.com','sample-hash','Uma Clark','555-0119'),(20,'sitter10@petcare.com','sample-hash','Victor Lewis','555-0120');

INSERT IGNORE INTO Client(UserID,EmergencyContactName,EmergencyContactPhone) VALUES
(1,'Morgan Chen','555-1101'),(2,'Taylor Lee','555-1102'),(3,'Sam Rivera','555-1103'),(4,'Ravi Patel','555-1104'),(5,'Min Kim','555-1105'),
(6,'Jamie Wong','555-1106'),(7,'Casey Smith','555-1107'),(8,'Robin Davis','555-1108'),(9,'Luis Garcia','555-1109'),(10,'Avery Brown','555-1110');

INSERT IGNORE INTO Sitter(UserID,BusinessName,Bio,ServiceArea) VALUES
(11,'PetCare Manager','Reliable in-home pet care and boarding.','San Jose'),
(12,'Paws and Paths','Dog walking and daycare.','Santa Clara'),(13,'Happy Tails','Experienced overnight care.','Sunnyvale'),
(14,'Cozy Critters','Small-pet and cat care.','Mountain View'),(15,'Bark Avenue','Daily walks and playtime.','Cupertino'),
(16,'Furry Friends','Weekend boarding services.','Milpitas'),(17,'Pawfect Care','Medication support available.','Fremont'),
(18,'Whisker Watch','Cat sitting and home visits.','Redwood City'),(19,'Golden Leash','Large-dog boarding.','San Jose'),(20,'Home Pet Helpers','Flexible drop-off care.','Campbell');

INSERT IGNORE INTO Address(AddressID,UserID,Street,City,State,ZipCode,AddressType) VALUES
(1,1,'101 Oak Street','San Jose','CA','95112','Home'),(2,2,'202 Pine Avenue','Santa Clara','CA','95050','Home'),
(3,3,'303 Cedar Road','Sunnyvale','CA','94087','Home'),(4,4,'404 Maple Drive','San Jose','CA','95126','Home'),
(5,5,'505 Elm Street','Milpitas','CA','95035','Home'),(6,6,'606 Spruce Lane','Campbell','CA','95008','Home'),
(7,7,'707 Willow Way','Cupertino','CA','95014','Home'),(8,8,'808 Birch Court','Fremont','CA','94536','Home'),
(9,9,'909 Redwood Road','San Jose','CA','95118','Home'),(10,10,'1001 Ash Boulevard','Santa Clara','CA','95051','Home');

INSERT IGNORE INTO Pet(PetID,OwnerID,PetName,Species,Breed,Age,Gender,Color,FavoriteToys,EmergencyNotes) VALUES
(1,1,'Milo','Dog','Golden Retriever',4,'Male','Golden','Tennis ball','Allergic to chicken'),(2,2,'Luna','Cat','Siamese',3,'Female','Cream','Feather wand','Needs quiet space'),
(3,3,'Charlie','Dog','Corgi',6,'Male','Brown and white','Rope toy','Sensitive stomach'),(4,4,'Bella','Dog','Poodle',2,'Female','White','Squeaky donut','No stairs'),
(5,5,'Oliver','Cat','Domestic Shorthair',5,'Male','Gray','Laser pointer','Indoor only'),(6,6,'Coco','Dog','Beagle',7,'Female','Tri-color','Chew bone','Medication with food'),
(7,7,'Max','Dog','Labrador',1,'Male','Black','Frisbee','High energy'),(8,8,'Daisy','Cat','Ragdoll',4,'Female','White and gray','Catnip mouse','Shy around strangers'),
(9,9,'Rocky','Dog','Husky',5,'Male','Black and white','Rubber ball','Must stay leashed'),(10,10,'Nala','Rabbit','Lionhead',2,'Female','Tan','Willow sticks','Fresh hay required');

INSERT IGNORE INTO Service(ServiceID,SitterID,ServiceName,Category,Description,Price,DurationMinutes,Capacity) VALUES
(1,11,'Dog Walking','Walking','Neighborhood walk',28,30,1),(2,11,'Extended Dog Walk','Walking','Long exercise walk',45,60,1),
(3,11,'Day Care','Day Care','Daytime supervision',45,480,5),(4,11,'Overnight Boarding','Boarding','Overnight care',63,1440,2),
(5,11,'House Sitting','House Sitting','Care at the client home',75,1440,1),(6,11,'Puppy Visit','Drop-in','Feeding and play visit',25,30,1),
(7,11,'Medication Visit','Drop-in','Medication and wellness check',30,30,1),(8,11,'Cat Sitting','Cat Care','Cat feeding and litter care',32,45,2),
(9,11,'Holiday Boarding','Boarding','Holiday overnight care',80,1440,2),(10,11,'Pet Taxi','Transportation','Local pet transportation',35,45,1);

INSERT IGNORE INTO Booking(BookingID,ClientID,SitterID,AddressID,StartDateTime,EndDateTime,Status) VALUES
(1,1,11,1,'2026-10-01 09:00:00','2026-10-01 09:30:00','COMPLETED'),(2,2,11,2,'2026-10-02 10:00:00','2026-10-02 10:45:00','COMPLETED'),
(3,3,11,3,'2026-10-03 08:00:00','2026-10-03 08:30:00','COMPLETED'),(4,4,11,4,'2026-10-04 12:00:00','2026-10-04 13:00:00','COMPLETED'),
(5,5,11,5,'2026-10-05 14:00:00','2026-10-05 14:45:00','COMPLETED'),(6,6,11,6,'2026-10-06 09:00:00','2026-10-06 09:30:00','COMPLETED'),
(7,7,11,7,'2026-10-07 11:00:00','2026-10-07 11:30:00','COMPLETED'),(8,8,11,8,'2026-10-08 15:00:00','2026-10-08 15:45:00','COMPLETED'),
(9,9,11,9,'2026-10-09 16:00:00','2026-10-09 16:45:00','COMPLETED'),(10,10,11,10,'2026-10-10 13:00:00','2026-10-10 13:45:00','COMPLETED');

INSERT IGNORE INTO BookingPet(BookingID,PetID) VALUES (1,1),(2,2),(3,3),(4,4),(5,5),(6,6),(7,7),(8,8),(9,9),(10,10);
INSERT IGNORE INTO BookingService(BookingID,ServiceID,PriceAtBooking) VALUES (1,1,28),(2,8,32),(3,1,28),(4,2,45),(5,8,32),(6,7,30),(7,1,28),(8,8,32),(9,2,45),(10,6,25);
INSERT IGNORE INTO CareInstruction(BookingID,PetID,FeedingInstructions,MedicationNeeds,BehavioralNotes,EmergencyNotes) VALUES
(1,1,'Breakfast at 8 AM','None','Friendly','Call owner if limping'),(2,2,'Wet food at 6 PM','None','Shy','Keep indoors'),(3,3,'Small meals twice daily','None','Pulls on leash','Sensitive stomach'),
(4,4,'Regular food','None','Calm','Avoid stairs'),(5,5,'Dry food available','None','Quiet','Indoor only'),(6,6,'Feed after medication','Heart medication','Gentle','Give medication with food'),
(7,7,'Three meals daily','None','Very energetic','Use secure leash'),(8,8,'Wet food at night','None','Shy','Do not force interaction'),(9,9,'Two meals daily','None','Strong puller','Double leash'),(10,10,'Unlimited hay','None','Gentle','Keep away from dogs');
INSERT IGNORE INTO Payment(PaymentID,BookingID,Amount,PaymentMethod,PaymentStatus) VALUES
(1,1,28,'Credit Card','Paid'),(2,2,32,'Venmo','Paid'),(3,3,28,'Cash','Paid'),(4,4,45,'Zelle','Paid'),(5,5,32,'Credit Card','Paid'),
(6,6,30,'Cash','Paid'),(7,7,28,'Venmo','Paid'),(8,8,32,'Zelle','Paid'),(9,9,45,'Credit Card','Paid'),(10,10,25,'Cash','Paid');
INSERT IGNORE INTO Review(ReviewID,BookingID,ClientID,Rating,Comment,TipAmount) VALUES
(1,1,1,5,'Very reliable.',5),(2,2,2,5,'Luna was happy.',5),(3,3,3,4,'Good walk.',0),(4,4,4,5,'Excellent care.',10),(5,5,5,5,'Great communication.',5),
(6,6,6,4,'Very helpful.',0),(7,7,7,5,'Max had a great time.',8),(8,8,8,5,'Thank you.',5),(9,9,9,4,'Rocky was well cared for.',0),(10,10,10,5,'Would book again.',10);
INSERT IGNORE INTO CareEvent(EventID,BookingID,PetID,EventType,EventTime) VALUES
(1,1,1,'DropOff','2026-10-01 09:00:00'),(2,2,2,'DropOff','2026-10-02 10:00:00'),(3,3,3,'DropOff','2026-10-03 08:00:00'),(4,4,4,'DropOff','2026-10-04 12:00:00'),(5,5,5,'DropOff','2026-10-05 14:00:00'),
(6,6,6,'PickUp','2026-10-06 09:30:00'),(7,7,7,'PickUp','2026-10-07 11:30:00'),(8,8,8,'PickUp','2026-10-08 15:45:00'),(9,9,9,'PickUp','2026-10-09 16:45:00'),(10,10,10,'PickUp','2026-10-10 13:45:00');
INSERT IGNORE INTO AuditLog(LogID,UserID,Action,Description) VALUES
(1,11,'CREATE_BOOKING','Created booking 1'),(2,11,'UPDATE_BOOKING','Confirmed booking 2'),(3,11,'RECORD_PAYMENT','Recorded payment 3'),(4,11,'UPDATE_SERVICE','Updated Dog Walking'),(5,11,'COMPLETE_BOOKING','Completed booking 5'),
(6,11,'CREATE_BOOKING','Created booking 6'),(7,11,'UPDATE_BOOKING','Completed booking 7'),(8,11,'RECORD_PAYMENT','Recorded payment 8'),(9,11,'UPDATE_SERVICE','Updated Cat Sitting'),(10,11,'COMPLETE_BOOKING','Completed booking 10');
