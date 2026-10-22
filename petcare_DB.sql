CREATE DATABASE  IF NOT EXISTS `petcare_manager` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `petcare_manager`;
-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: petcare_manager
-- ------------------------------------------------------
-- Server version	26.7.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ 'beb52ddb-a659-11f1-9088-1cce51e979be:1-54';

--
-- Table structure for table `address`
--

DROP TABLE IF EXISTS `address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `address` (
  `AddressID` int NOT NULL AUTO_INCREMENT,
  `UserID` int NOT NULL,
  `Street` varchar(150) NOT NULL,
  `City` varchar(60) NOT NULL,
  `State` char(2) NOT NULL,
  `ZipCode` varchar(10) NOT NULL,
  `AddressType` enum('HOME','BUSINESS','OTHER') NOT NULL,
  PRIMARY KEY (`AddressID`),
  KEY `UserID` (`UserID`),
  CONSTRAINT `address_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `user` (`UserID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `address`
--

LOCK TABLES `address` WRITE;
/*!40000 ALTER TABLE `address` DISABLE KEYS */;
INSERT INTO `address` VALUES (1,1,'245 N 4th St','San Jose','CA','95112','HOME'),(2,2,'1780 Homestead Rd','Santa Clara','CA','95050','HOME'),(3,3,'930 E El Camino Real','Sunnyvale','CA','94087','HOME'),(4,4,'512 Almaden Ave','San Jose','CA','95110','HOME'),(5,5,'3350 Stevens Creek Blvd','San Jose','CA','95117','HOME'),(6,6,'10200 Bubb Rd','Cupertino','CA','95014','HOME'),(7,7,'88 S 10th St','San Jose','CA','95112','HOME'),(8,8,'15 University Ave','Los Gatos','CA','95030','HOME'),(9,11,'1190 Lincoln Ave','San Jose','CA','95125','BUSINESS'),(10,15,'7450 Monterey St','Gilroy','CA','95020','BUSINESS');
/*!40000 ALTER TABLE `address` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `LogID` int NOT NULL AUTO_INCREMENT,
  `UserID` int NOT NULL,
  `Action` varchar(50) NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `ActionTime` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`LogID`),
  KEY `UserID` (`UserID`),
  CONSTRAINT `audit_log_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `user` (`UserID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
INSERT INTO `audit_log` VALUES (1,11,'CONFIRM_BOOKING','Confirmed booking 1','2026-07-25 11:00:00'),(2,12,'CONFIRM_BOOKING','Confirmed booking 2','2026-08-01 13:00:00'),(3,19,'UPDATE_BOOKING','Marked booking 3 as COMPLETED','2026-08-07 12:10:00'),(4,15,'CONFIRM_BOOKING','Confirmed booking 4','2026-08-08 12:30:00'),(5,11,'UPDATE_SERVICE','Changed Overnight Boarding price from 60.00 to 65.00','2026-08-20 09:00:00'),(6,13,'REFUND_PAYMENT','Refunded payment for booking 7','2026-09-06 10:00:00'),(7,16,'UPDATE_BOOKING','Marked booking 8 as COMPLETED','2026-09-10 17:05:00'),(8,11,'SUSPEND_ACCOUNT','Suspended client 10: repeated no-shows','2026-09-14 10:00:00'),(9,14,'DEACTIVATE_SERVICE','Set Group Walk to UNAVAILABLE','2026-09-20 15:00:00'),(10,12,'UPDATE_BOOKING','Marked booking 10 as COMPLETED','2026-09-25 09:05:00');
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `booking`
--

DROP TABLE IF EXISTS `booking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking` (
  `BookingID` int NOT NULL AUTO_INCREMENT,
  `ClientID` int NOT NULL,
  `SitterID` int NOT NULL,
  `AddressID` int NOT NULL,
  `StartDateTime` datetime NOT NULL,
  `EndDateTime` datetime NOT NULL,
  `Status` enum('REQUESTED','CONFIRMED','IN_PROGRESS','COMPLETED','CANCELLED','DECLINED') NOT NULL DEFAULT 'REQUESTED',
  `CreatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`BookingID`),
  KEY `ClientID` (`ClientID`),
  KEY `SitterID` (`SitterID`),
  KEY `AddressID` (`AddressID`),
  CONSTRAINT `booking_ibfk_1` FOREIGN KEY (`ClientID`) REFERENCES `client` (`UserID`),
  CONSTRAINT `booking_ibfk_2` FOREIGN KEY (`SitterID`) REFERENCES `sitter` (`UserID`),
  CONSTRAINT `booking_ibfk_3` FOREIGN KEY (`AddressID`) REFERENCES `address` (`AddressID`),
  CONSTRAINT `booking_chk_1` CHECK ((`EndDateTime` > `StartDateTime`))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking`
--

LOCK TABLES `booking` WRITE;
/*!40000 ALTER TABLE `booking` DISABLE KEYS */;
INSERT INTO `booking` VALUES (1,1,11,9,'2026-08-01 09:00:00','2026-08-03 17:00:00','COMPLETED','2026-07-25 10:00:00'),(2,2,12,2,'2026-08-05 08:00:00','2026-08-05 09:00:00','COMPLETED','2026-08-01 12:30:00'),(3,3,19,3,'2026-08-07 08:00:00','2026-08-07 12:00:00','COMPLETED','2026-08-03 09:15:00'),(4,5,15,10,'2026-08-14 10:00:00','2026-08-17 10:00:00','COMPLETED','2026-08-08 11:45:00'),(5,6,17,6,'2026-08-20 18:00:00','2026-08-23 09:00:00','COMPLETED','2026-08-12 20:10:00'),(6,8,18,8,'2026-09-01 07:30:00','2026-09-01 09:30:00','COMPLETED','2026-08-28 16:00:00'),(7,1,13,1,'2026-09-05 12:00:00','2026-09-05 12:45:00','COMPLETED','2026-09-02 10:20:00'),(8,4,16,4,'2026-09-10 08:00:00','2026-09-10 17:00:00','COMPLETED','2026-09-04 14:05:00'),(9,1,11,9,'2026-09-15 09:00:00','2026-09-16 17:00:00','COMPLETED','2026-09-10 08:40:00'),(10,7,12,7,'2026-09-25 08:00:00','2026-09-25 09:00:00','COMPLETED','2026-09-21 21:15:00');
/*!40000 ALTER TABLE `booking` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `booking_pet`
--

DROP TABLE IF EXISTS `booking_pet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking_pet` (
  `BookingID` int NOT NULL,
  `PetID` int NOT NULL,
  PRIMARY KEY (`BookingID`,`PetID`),
  KEY `PetID` (`PetID`),
  CONSTRAINT `booking_pet_ibfk_1` FOREIGN KEY (`BookingID`) REFERENCES `booking` (`BookingID`),
  CONSTRAINT `booking_pet_ibfk_2` FOREIGN KEY (`PetID`) REFERENCES `pet` (`PetID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking_pet`
--

LOCK TABLES `booking_pet` WRITE;
/*!40000 ALTER TABLE `booking_pet` DISABLE KEYS */;
INSERT INTO `booking_pet` VALUES (1,1),(9,1),(7,2),(2,3),(3,4),(8,5),(4,6),(5,7),(10,8),(6,9);
/*!40000 ALTER TABLE `booking_pet` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `booking_service`
--

DROP TABLE IF EXISTS `booking_service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `booking_service` (
  `BookingID` int NOT NULL,
  `ServiceID` int NOT NULL,
  `PriceAtBooking` decimal(8,2) NOT NULL,
  PRIMARY KEY (`BookingID`,`ServiceID`),
  KEY `ServiceID` (`ServiceID`),
  CONSTRAINT `booking_service_ibfk_1` FOREIGN KEY (`BookingID`) REFERENCES `booking` (`BookingID`),
  CONSTRAINT `booking_service_ibfk_2` FOREIGN KEY (`ServiceID`) REFERENCES `service` (`ServiceID`),
  CONSTRAINT `booking_service_chk_1` CHECK ((`PriceAtBooking` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `booking_service`
--

LOCK TABLES `booking_service` WRITE;
/*!40000 ALTER TABLE `booking_service` DISABLE KEYS */;
INSERT INTO `booking_service` VALUES (1,2,60.00),(2,3,40.00),(3,10,28.00),(4,6,70.00),(5,8,90.00),(6,9,55.00),(7,4,30.00),(8,7,45.00),(9,2,65.00),(10,3,40.00);
/*!40000 ALTER TABLE `booking_service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `care_event`
--

DROP TABLE IF EXISTS `care_event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `care_event` (
  `EventID` int NOT NULL AUTO_INCREMENT,
  `BookingID` int NOT NULL,
  `PetID` int NOT NULL,
  `EventType` enum('DROP_OFF','PICK_UP') NOT NULL,
  `EventTime` datetime NOT NULL,
  PRIMARY KEY (`EventID`),
  KEY `BookingID` (`BookingID`,`PetID`),
  CONSTRAINT `care_event_ibfk_1` FOREIGN KEY (`BookingID`, `PetID`) REFERENCES `booking_pet` (`BookingID`, `PetID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `care_event`
--

LOCK TABLES `care_event` WRITE;
/*!40000 ALTER TABLE `care_event` DISABLE KEYS */;
INSERT INTO `care_event` VALUES (1,1,1,'DROP_OFF','2026-08-01 09:05:00'),(2,1,1,'PICK_UP','2026-08-03 17:20:00'),(3,3,4,'DROP_OFF','2026-08-07 08:02:00'),(4,3,4,'PICK_UP','2026-08-07 12:05:00'),(5,4,6,'DROP_OFF','2026-08-14 10:10:00'),(6,4,6,'PICK_UP','2026-08-17 10:15:00'),(7,8,5,'DROP_OFF','2026-09-10 07:55:00'),(8,8,5,'PICK_UP','2026-09-10 17:10:00'),(9,9,1,'DROP_OFF','2026-09-15 09:00:00'),(10,9,1,'PICK_UP','2026-09-16 16:50:00');
/*!40000 ALTER TABLE `care_event` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `care_instruction`
--

DROP TABLE IF EXISTS `care_instruction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `care_instruction` (
  `InstructionID` int NOT NULL AUTO_INCREMENT,
  `BookingID` int NOT NULL,
  `PetID` int NOT NULL,
  `FeedingInstructions` varchar(255) DEFAULT NULL,
  `MedicationNeeds` varchar(255) DEFAULT NULL,
  `BehavioralNotes` varchar(255) DEFAULT NULL,
  `EmergencyNotes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`InstructionID`),
  UNIQUE KEY `BookingID` (`BookingID`,`PetID`),
  CONSTRAINT `care_instruction_ibfk_1` FOREIGN KEY (`BookingID`, `PetID`) REFERENCES `booking_pet` (`BookingID`, `PetID`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `care_instruction`
--

LOCK TABLES `care_instruction` WRITE;
/*!40000 ALTER TABLE `care_instruction` DISABLE KEYS */;
INSERT INTO `care_instruction` VALUES (1,1,1,'2 cups kibble at 7am and 6pm',NULL,'Friendly, pulls on leash','Allergic to chicken'),(2,2,3,'No food during walk','Joint supplement at 7am','Slow on hills','Hip issues, avoid stairs'),(3,3,4,'Lunch snack at 11am',NULL,'Shy with big dogs','Escape artist, check gates'),(4,4,6,'Half cup soft food twice daily','Heart pill with breakfast','Gets anxious at night','Call owner if coughing'),(5,5,7,'Wet food at 8am and 8pm',NULL,'Hides from strangers at first',NULL),(6,6,9,'Water breaks every 30 minutes',NULL,'Herds other dogs, keep on leash',NULL),(7,7,2,'Quarter cup dry food',NULL,'Needs a quiet room',NULL),(8,8,5,'1 cup kibble at noon',NULL,'Loves fetch, very social',NULL),(9,9,1,'2 cups kibble at 7am and 6pm',NULL,'Friendly, pulls on leash','Allergic to chicken'),(10,10,8,'Treats only after the walk',NULL,'Sniffs everything, go slow','Eats anything, watch trash');
/*!40000 ALTER TABLE `care_instruction` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `client`
--

DROP TABLE IF EXISTS `client`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `client` (
  `UserID` int NOT NULL,
  `EmergencyContactName` varchar(100) DEFAULT NULL,
  `EmergencyContactPhone` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`UserID`),
  CONSTRAINT `client_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `user` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `client`
--

LOCK TABLES `client` WRITE;
/*!40000 ALTER TABLE `client` DISABLE KEYS */;
INSERT INTO `client` VALUES (1,'Mark Carter','408-555-2286'),(2,'Linh Nguyen','650-555-2080'),(3,'Arjun Raman','650-555-1481'),(4,'Rosa Ortiz','650-555-3300'),(5,'Wei Chen','650-555-6360'),(6,'Sarah Whitaker','408-555-7075'),(7,'Omar Mohammed','650-555-3080'),(8,'Jenny Park','650-555-8780'),(9,'Luis Gomez','650-555-3633'),(10,'Neha Patel','669-555-5514');
/*!40000 ALTER TABLE `client` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payment`
--

DROP TABLE IF EXISTS `payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment` (
  `PaymentID` int NOT NULL AUTO_INCREMENT,
  `BookingID` int NOT NULL,
  `Amount` decimal(8,2) NOT NULL,
  `PaymentMethod` enum('CASH','CREDIT_CARD','VENMO','ZELLE') NOT NULL,
  `PaymentStatus` enum('PENDING','PAID','REFUNDED') NOT NULL DEFAULT 'PENDING',
  `PaymentTime` datetime DEFAULT NULL,
  PRIMARY KEY (`PaymentID`),
  UNIQUE KEY `BookingID` (`BookingID`),
  CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`BookingID`) REFERENCES `booking` (`BookingID`),
  CONSTRAINT `payment_chk_1` CHECK ((`Amount` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment`
--

LOCK TABLES `payment` WRITE;
/*!40000 ALTER TABLE `payment` DISABLE KEYS */;
INSERT INTO `payment` VALUES (1,1,120.00,'VENMO','PAID','2026-08-03 17:30:00'),(2,2,40.00,'CASH','PAID','2026-08-05 09:05:00'),(3,3,28.00,'ZELLE','PAID','2026-08-07 12:10:00'),(4,4,210.00,'CREDIT_CARD','PAID','2026-08-17 10:20:00'),(5,5,270.00,'ZELLE','PAID','2026-08-23 09:30:00'),(6,6,55.00,'VENMO','PAID','2026-09-01 09:45:00'),(7,7,30.00,'VENMO','REFUNDED','2026-09-06 10:00:00'),(8,8,45.00,'CREDIT_CARD','PAID','2026-09-10 17:15:00'),(9,9,65.00,'CASH','PAID','2026-09-16 17:10:00'),(10,10,40.00,'VENMO','PENDING',NULL);
/*!40000 ALTER TABLE `payment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pet`
--

DROP TABLE IF EXISTS `pet`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pet` (
  `PetID` int NOT NULL AUTO_INCREMENT,
  `OwnerID` int NOT NULL,
  `PetName` varchar(50) NOT NULL,
  `Species` varchar(30) NOT NULL,
  `Breed` varchar(50) DEFAULT NULL,
  `Age` int DEFAULT NULL,
  `Gender` enum('Male','Female','Unknown') DEFAULT NULL,
  `Color` varchar(50) DEFAULT NULL,
  `Markings` varchar(100) DEFAULT NULL,
  `FavoriteToys` varchar(100) DEFAULT NULL,
  `EmergencyNotes` varchar(255) DEFAULT NULL,
  `PhotoURL` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`PetID`),
  KEY `OwnerID` (`OwnerID`),
  CONSTRAINT `pet_ibfk_1` FOREIGN KEY (`OwnerID`) REFERENCES `client` (`UserID`),
  CONSTRAINT `pet_chk_1` CHECK ((`Age` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pet`
--

LOCK TABLES `pet` WRITE;
/*!40000 ALTER TABLE `pet` DISABLE KEYS */;
INSERT INTO `pet` VALUES (1,1,'Biscuit','Dog','Golden Retriever',4,'Male','Golden','None','Tennis ball','Allergic to chicken','lorem_ipsum_jpg'),(2,1,'Luna','Cat','Domestic Shorthair',2,'Female','Gray','White paws','Feather wand',NULL,'lorem_ipsum_jpg'),(3,2,'Rocky','Dog','German Shepherd',6,'Male','Black and tan','Saddle pattern','Rope toy','Hip issues, avoid stairs','lorem_ipsum_jpg'),(4,3,'Mochi','Dog','Shiba Inu',3,'Female','Red','Cream chest','Squeaky duck','Escape artist, check gates','lorem_ipsum_jpg'),(5,4,'Max','Dog','Labrador Retriever',5,'Male','Black','None','Frisbee',NULL,'lorem_ipsum_jpg'),(6,5,'Coco','Dog','Toy Poodle',8,'Female','Apricot','None','Plush bunny','Heart murmur, no hard exercise','lorem_ipsum_jpg'),(7,6,'Oliver','Cat','Maine Coon',5,'Male','Brown tabby','Striped tail','Catnip mouse',NULL,'lorem_ipsum_jpg'),(8,7,'Bella','Dog','Beagle',2,'Female','Tricolor','White tail tip','Kong','Eats anything, watch trash','lorem_ipsum_jpg'),(9,8,'Pepper','Dog','Border Collie',1,'Female','Black and white','White blaze','Ball launcher',NULL,'lorem_ipsum_jpg'),(10,9,'Simba','Cat','Orange Tabby',7,'Male','Orange','Striped','Laser pointer','Diabetic, insulin at 8am','lorem_ipsum_jpg');
/*!40000 ALTER TABLE `pet` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `review`
--

DROP TABLE IF EXISTS `review`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `review` (
  `ReviewID` int NOT NULL AUTO_INCREMENT,
  `BookingID` int NOT NULL,
  `ClientID` int NOT NULL,
  `Rating` int NOT NULL,
  `Comment` varchar(500) DEFAULT NULL,
  `TipAmount` decimal(8,2) DEFAULT '0.00',
  `ReviewDate` date NOT NULL,
  PRIMARY KEY (`ReviewID`),
  UNIQUE KEY `BookingID` (`BookingID`),
  KEY `ClientID` (`ClientID`),
  CONSTRAINT `review_ibfk_1` FOREIGN KEY (`BookingID`) REFERENCES `booking` (`BookingID`),
  CONSTRAINT `review_ibfk_2` FOREIGN KEY (`ClientID`) REFERENCES `client` (`UserID`),
  CONSTRAINT `review_chk_1` CHECK ((`Rating` between 1 and 5)),
  CONSTRAINT `review_chk_2` CHECK ((`TipAmount` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `review`
--

LOCK TABLES `review` WRITE;
/*!40000 ALTER TABLE `review` DISABLE KEYS */;
INSERT INTO `review` VALUES (1,1,1,5,'Biscuit came home happy and tired. Great photo updates.',15.00,'2026-08-04'),(2,2,2,4,'Good walk, arrived 10 minutes late.',5.00,'2026-08-06'),(3,3,3,5,'Mochi loved the play group.',0.00,'2026-08-08'),(4,4,5,5,'Very careful with Coco\'s medication.',20.00,'2026-08-18'),(5,5,6,4,'House was clean, Oliver was relaxed.',10.00,'2026-08-24'),(6,6,8,5,'Pepper finally got tired! Will book again.',10.00,'2026-09-02'),(7,7,1,2,'Sitter left early, so the visit was refunded.',0.00,'2026-09-06'),(8,8,4,5,'Max learned to sit on command!',10.00,'2026-09-11'),(9,9,1,5,'Second stay, just as good as the first.',10.00,'2026-09-17'),(10,10,7,3,'Walk was fine, but Bella came back muddy.',0.00,'2026-09-26');
/*!40000 ALTER TABLE `review` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `service`
--

DROP TABLE IF EXISTS `service`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `service` (
  `ServiceID` int NOT NULL AUTO_INCREMENT,
  `SitterID` int NOT NULL,
  `ServiceName` varchar(100) NOT NULL,
  `Category` enum('WALKING','BOARDING','DAYCARE','HOUSE_SITTING') NOT NULL,
  `Description` varchar(255) DEFAULT NULL,
  `Price` decimal(8,2) NOT NULL,
  `DurationMinutes` int NOT NULL,
  `Capacity` int NOT NULL,
  `AvailabilityStatus` enum('AVAILABLE','UNAVAILABLE') NOT NULL DEFAULT 'AVAILABLE',
  PRIMARY KEY (`ServiceID`),
  KEY `SitterID` (`SitterID`),
  CONSTRAINT `service_ibfk_1` FOREIGN KEY (`SitterID`) REFERENCES `sitter` (`UserID`),
  CONSTRAINT `service_chk_1` CHECK ((`Price` >= 0)),
  CONSTRAINT `service_chk_2` CHECK ((`DurationMinutes` > 0)),
  CONSTRAINT `service_chk_3` CHECK ((`Capacity` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `service`
--

LOCK TABLES `service` WRITE;
/*!40000 ALTER TABLE `service` DISABLE KEYS */;
INSERT INTO `service` VALUES (1,11,'Dog Walk (30 min)','WALKING','Neighborhood walk, one dog',25.00,30,3,'AVAILABLE'),(2,11,'Overnight Boarding','BOARDING','Boarding at sitter home, per night',65.00,1440,4,'AVAILABLE'),(3,12,'Dog Walk (60 min)','WALKING','Long walk for high-energy dogs',40.00,60,2,'AVAILABLE'),(4,13,'Cat Drop-In Visit','HOUSE_SITTING','Feeding, litter, and playtime',30.00,45,1,'AVAILABLE'),(5,14,'Group Walk','WALKING','Walk with up to 5 dogs',20.00,60,5,'UNAVAILABLE'),(6,15,'Overnight Boarding','BOARDING','Boarding with fenced yard, per night',70.00,1440,3,'AVAILABLE'),(7,16,'Daycare Full Day','DAYCARE','Play and training, 8am to 5pm',45.00,540,6,'AVAILABLE'),(8,17,'Overnight House Sitting','HOUSE_SITTING','Sitter stays at client home, per night',90.00,1440,1,'AVAILABLE'),(9,18,'Adventure Hike','WALKING','Two-hour trail hike',55.00,120,4,'AVAILABLE'),(10,19,'Daycare Half Day','DAYCARE','Morning or afternoon play group',28.00,240,8,'AVAILABLE');
/*!40000 ALTER TABLE `service` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sitter`
--

DROP TABLE IF EXISTS `sitter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sitter` (
  `UserID` int NOT NULL,
  `BusinessName` varchar(100) NOT NULL,
  `Bio` varchar(500) DEFAULT NULL,
  `ServiceArea` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`UserID`),
  CONSTRAINT `sitter_ibfk_1` FOREIGN KEY (`UserID`) REFERENCES `user` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sitter`
--

LOCK TABLES `sitter` WRITE;
/*!40000 ALTER TABLE `sitter` DISABLE KEYS */;
INSERT INTO `sitter` VALUES (11,'Pawsitive Care','Certified pet first-aid sitter with 8 years of boarding experience.','San Jose'),(12,'Happy Tails Sitting','Dog walker who loves high-energy breeds.','Santa Clara'),(13,'Whisker Watch','Cat specialist offering calm in-home visits.','Sunnyvale'),(14,'Bay Paws Walkers','Small group walks around neighborhood parks.','San Jose'),(15,'Cozy Critter Boarding','Home boarding with a fenced backyard.','Gilroy'),(16,'Leash & Learn','Daycare with basic obedience practice.','San Jose'),(17,'Purrfect Stay','Overnight house sitting for cats and dogs.','Cupertino'),(18,'Trail Tails','Hiking adventures for active dogs.','Los Gatos'),(19,'Furry Friends Daycare','Supervised play groups, half and full day.','Milpitas'),(20,'HomeBase Pet Sitting','Reliable house sitting with daily photo updates.','Santa Clara');
/*!40000 ALTER TABLE `sitter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `UserID` int NOT NULL AUTO_INCREMENT,
  `Email` varchar(100) NOT NULL,
  `PasswordHash` varchar(255) NOT NULL,
  `FullName` varchar(100) NOT NULL,
  `Phone` varchar(20) DEFAULT NULL,
  `AccountStatus` enum('ACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
  `CreatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`UserID`),
  UNIQUE KEY `Email` (`Email`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'emily.carter@gmail.com','b3fa78d77d7d75392e780f6e8243810446ad4b788ca64877979e6d79c86b30a8','Emily Carter','650-555-9042','ACTIVE','2026-06-02 10:15:00'),(2,'marcus.nguyen@gmail.com','2689649291080fafab120eaf697e844eea7df8e47a55015978adcb63a3c2dd2d','Marcus Nguyen','408-565-3631','ACTIVE','2026-06-05 14:20:00'),(3,'priya.raman@yahoo.com','f37b7cb06f73adcead6011b14c1147245bc7153bfd95a3efe3c2f2011e8e009f','Priya Raman','408-755-1486','ACTIVE','2026-06-08 09:05:00'),(4,'daniel.ortiz@outlook.com','7d48be451fb7ba187c09811a281bf81102816e85d112f95000bc06ed4701ff90','Daniel Ortiz','669-555-6678','ACTIVE','2026-06-11 18:40:00'),(5,'sophie.chen@gmail.com','4faa8f9feecfc1762ed09a148b31636b2c3646eebe5b827152dc52cae8ad75f8','Sophie Chen','408-555-6204','ACTIVE','2026-06-15 11:30:00'),(6,'james.whitaker@gmail.com','a217fbb7f6896a09b41d715298b60e066a7b746c6adc85556498ca61c76f2771','James Whitaker','408-905-2483','ACTIVE','2026-06-20 16:45:00'),(7,'aisha.mohammed@gmail.com','267047bc57015388e0f5cb23d6c91975bddbef017da5080e57d8813c82d2e09c','Aisha Mohammed','408-533-4673','ACTIVE','2026-06-24 08:10:00'),(8,'kevin.park@icloud.com','4058686b68c702ae7bb8b73b15d87a52ad1247a6e295450f94bd67a799d06d8c','Kevin Park','650-505-2731','ACTIVE','2026-07-01 12:00:00'),(9,'laura.gomez@gmail.com','2241cea3095c04d6f3fe6913609c88926b1eec248be188d4008a6215fbfe3900','Laura Gomez','408-505-2804','ACTIVE','2026-07-06 19:25:00'),(10,'ryan.patel@gmail.com','404f65f8cbd4a1386493618bf3a0c55a617f812ccbe25a1b83a718ac09d5aced','Ryan Patel','650-545-7420','SUSPENDED','2026-07-10 13:50:00'),(11,'maria@pawsitivecare.com','c938f8df4d2d3f027285212e1428366655d9ac4f275efe2104b472026f1188f7','Maria Lopez','669-595-7229','ACTIVE','2026-05-01 09:12:00'),(12,'jordan@happytails.com','573e58bb11a1d603cd6233a05f83565217013c3146f79aa539315ed790424986','Jordan Blake','669-996-2673','ACTIVE','2026-05-03 14:37:00'),(13,'hannah@whiskerwatch.com','c038c137f77f0dab820a41604875fde98a6aaa735b8854c10fa2149b6e878872','Hannah Kim','669-532-8789','ACTIVE','2026-05-05 10:48:00'),(14,'carlos@baypaws.com','502b148f1eecfa97be72972935cdb3b6f104b342e7df71252a195ff470188597','Carlos Rivera','408-167-1440','ACTIVE','2026-05-07 16:05:00'),(15,'olivia@cozycritter.com','2e625b1e821a5c661927d47a315b50a445fdad3e8d0f102800f9058e9b274dc9','Olivia Bennett','650-221-2842','ACTIVE','2026-05-09 08:21:00'),(16,'ethan@leashandlearn.com','216dc06601b3b68d247fece6601c4eaccffb84fbbed6a3ccb8db7a29f76294a4','Ethan Wu','669-099-6547','ACTIVE','2026-05-11 13:56:00'),(17,'grace@purrfectstay.com','8960e6ca3000da80d50b61e2b950e4284d9526cf5d611aef2574e32c8f78e366','Grace Thompson','669-311-6889','ACTIVE','2026-05-13 19:03:00'),(18,'noah@trailtails.com','dd3fd793f46dda6cd90dc1c1508c17256b0c7dd36b057a59765d9a5f9a011277','Noah Silva','650-101-4979','ACTIVE','2026-05-15 11:40:00'),(19,'chloe@furryfriends.com','7c3bb1a397013dbe0df5adb2faf650536bc2073c5bad68fec9255c3e938b7d50','Chloe Adams','669-223-2506','ACTIVE','2026-05-17 15:18:00'),(20,'liam@homebasepets.com','21bdcdc30cf568dd9f990549ff64058a7613d65c09e9e55b2321ab50649b6aea','Liam Foster','669-477-6647','ACTIVE','2026-05-19 09:44:00');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'petcare_manager'
--
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-30 15:03:31
