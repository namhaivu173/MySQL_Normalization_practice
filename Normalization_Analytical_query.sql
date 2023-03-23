# Create new database to store our data
DROP DATABASE IF EXISTS airports;
CREATE DATABASE airports;
SHOW DATABASES;
USE airports;

# Create table airport_list
DROP TABLE IF EXISTS airport_list;
CREATE TABLE airport_list(
iata varchar(255),
airport varchar(255),
city varchar(255),
state varchar(255),
country varchar(255),
latitude decimal(10,7),
longitude decimal(10,7),
cnt int);

# Adjust NOT NULL constraints
ALTER TABLE airport_list
MODIFY iata varchar(255) NOT NULL,
MODIFY airport varchar(255) NOT NULL;

# Check if data import is successful
SELECT * FROM airport_list;

# Check if there are any blanks
SELECT * FROM airport_list
WHERE 
	"" IN (iata, airport, city, state, country, latitude, longitude, cnt) or 
	NULL IN (iata, airport, city, state, country, latitude, longitude, cnt);

# Replace blanks with "Unknown" value
UPDATE airport_list
SET city = "Unknown",
    state = "Unknown"
WHERE iata = "MQT";

# Check if value is replaced
SELECT * FROM airport_list
WHERE iata = "MQT";

# Check if airport code is unique for each row
SELECT 
	COUNT(*) as Total_Rows,
	COUNT(DISTINCT iata) as Num_Unique_Airports,
    COUNT(DISTINCT country) as Num_Unique_Countries
FROM airport_list;

# Check unique values of "cnt"
SELECT
    cnt,
    COUNT(cnt) as Count_cnt
FROM airport_list
GROUP BY cnt
ORDER BY COUNT(cnt) DESC;

# Remove redundant column "country"
ALTER TABLE airport_list
DROP COLUMN country;

-- DESCRIBE airport_list;

#---------------------> Main table PK creation
# Normalize airport_list table to NF 1 by adding PK column
ALTER TABLE airport_list
ADD COLUMN listID INT NOT NULL PRIMARY KEY AUTO_INCREMENT;

# Check if id column is added
SELECT * FROM airport_list;

# Change column name
# ALTER TABLE airport_list RENAME COLUMN airportID TO listID; 

#---------------------> iata table creation
# Delete iata table if already exists
DROP TABLE IF EXISTS iata;

# Create new table iata 
# table iata will have PK and two fields name and code to store
CREATE TABLE iata (
	AirportID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    AirportCode VARCHAR(255) NOT NULL,
    AirportName VARCHAR(255) NOT NULL
);

# Verify table created but empty
SELECT * FROM iata;

# Insert airport information into Code and Name for iata table
INSERT INTO iata
(AirportCode, AirportName)
SELECT DISTINCT iata, airport
FROM airport_list;

# Verify table is filled
SELECT * FROM iata;

# Create airportID for airport_list
ALTER TABLE airport_list
ADD COLUMN AirportID INT NULL;

# Check if AirportID column is added
SELECT * FROM airport_list;

# Match information from iata table to airport table
UPDATE airport_list a, iata i
SET a.AirportID = i.AirportID
WHERE a.airport LIKE i.AirportName AND a.iata LIKE i.AirportCode;

# Remove redundant columns from airport_list table
ALTER TABLE airport_list
DROP COLUMN iata,
DROP COLUMN airport;

# Check if redundant columns are removed
SELECT * FROM airport_list;

# Create foreign key connection between airport_list and iata tables:
ALTER TABLE airport_list
ADD FOREIGN KEY (AirportID) REFERENCES iata(AirportID);

#---------------------> city table creation
# Create city table with an id column
DROP TABLE IF EXISTS city;
CREATE TABLE city (
	cityID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    cityName VARCHAR(255) NOT NULL
);

# Verify table is created
SELECT * FROM city;

# Insert airport information into cityName for city table
INSERT INTO city(cityName)
SELECT DISTINCT city
FROM airport_list;

# Verify table is created
SELECT * FROM city;

# Add cityID column to airport_list
ALTER TABLE airport_list
ADD COLUMN cityID INT NULL;

# Verify cityID column has been created
SELECT * FROM airport_list;

# Update cityID values in the airport_list table with ones from city Table
# Matching records by cityName
UPDATE airport_list a, city c
SET a.cityID = c.cityID
WHERE a.city LIKE c.cityName;

# Verify cityID column has been filled
SELECT * FROM airport_list;

# Drop city column
ALTER TABLE airport_list
DROP COLUMN city;

# Verify city column has been removed
SELECT * FROM airport_list;

# Create foreign key connection between airport_list and city tables:
ALTER TABLE airport_list
ADD FOREIGN KEY (cityID) REFERENCES city(cityID);

#---------------------> state table creation
# Create new table state with an id column
DROP TABLE IF EXISTS state;
CREATE TABLE state (
	stateID INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    stateName VARCHAR(255) NOT NULL
);

# Check if table is created
SELECT * FROM state;

# Insert airport information into stateName for state table
INSERT INTO state(stateName)
SELECT DISTINCT state
FROM airport_list;

# Check if state table is filled
SELECT * FROM state;

# Add stateID column to airport_list
ALTER TABLE airport_list
ADD COLUMN stateID INT NULL;

# Verify if stateID column is created
SELECT * FROM airport_list;

# Update stateID values in the airport_list table with ones from state Table
# Matching records by stateName
UPDATE airport_list a, state s
SET a.stateID = s.stateID
WHERE a.state LIKE s.stateName;

# Verify if stateID column is filled
SELECT * FROM airport_list;

# Drop state column
ALTER TABLE airport_list
DROP COLUMN state;

# Verify state column has been removed
SELECT * FROM airport_list;

# Create foreign key connection between airport_list and state tables:
ALTER TABLE airport_list
ADD FOREIGN KEY (stateID) REFERENCES state(stateID);

#---------------------> Answer business questions

# 1. Report location information of all airports in chicago
SELECT  i.AirportName as "Airport",
		i.AirportCode as "Code",
		c.cityName as "City",
        s.stateName as "State",
        a.latitude as "Latitude",
        a.longitude as "longitude"
FROM airport_list a
LEFT JOIN iata i on a.listID = i.AirportID
LEFT JOIN city c on a.cityID = c.cityID
LEFT JOIN state s on a.stateID = s.stateID
WHERE c.cityName = "Chicago";

# 2. Report information of all airports and their cities in the state of MA or IL
SELECT  i.AirportName as "Airport",
		i.AirportCode as "Code",
		c.cityName as "City",
        s.stateName as "State"
FROM airport_list a
LEFT JOIN iata i on a.listID = i.AirportID
LEFT JOIN city c on a.cityID = c.cityID
LEFT JOIN state s on a.stateID = s.stateID
WHERE s.stateName = "MA" or s.stateName = "IL";

# 3. Report airports with unknown cities or states
SELECT  i.AirportName as "Airport",
		c.cityName as "City",
        s.stateName as "State",
		a.latitude as "latitude",
        a.longitude as "longitude"
FROM airport_list a
LEFT JOIN iata i on a.listID = i.AirportID
LEFT JOIN city c on a.cityID = c.cityID
LEFT JOIN state s on a.stateID = s.stateID
WHERE s.stateName = "Unknown" or c.cityName = "Unknown";

# 4. Report airports in states whose names start with "M"
SELECT	ROW_NUMBER() OVER(ORDER BY s.stateName, i.AirportName) as "No.",
		i.AirportName as "Airport", 
		s.stateName as "State"
FROM airport_list a
LEFT JOIN state s on s.stateID = a.stateID
LEFT JOIN iata i on i.AirportID = a.AirportID
WHERE s.stateName LIKE "M%"
ORDER BY State, Airport;

# 5. Show states with the top 5 highest number of airports and their ranking
WITH CTE as (
SELECT	s.stateName as "State",
		COUNT(DISTINCT i.AirportName) as "Airport_Count",
		DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT i.AirportName) DESC) as "Ranking"
FROM airport_list a
LEFT JOIN state s on s.stateID = a.stateID
LEFT JOIN iata i on i.AirportID = a.AirportID
WHERE s.stateName != "Unknown"
GROUP BY s.stateName
ORDER BY Airport_Count DESC)
SELECT * FROM CTE
WHERE Ranking <= 5;






