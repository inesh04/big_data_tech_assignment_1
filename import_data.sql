USE taxi_db;
DROP TABLE IF EXISTS StagingTable;
CREATE TABLE StagingTable(
    staging_id INT AUTO_INCREMENT PRIMARY KEY,
    VendorID VARCHAR(50),
    tpep_pickup_datetime VARCHAR(50),
    tpep_dropoff_datetime VARCHAR(50),
    passenger_count VARCHAR(50),
    trip_distance VARCHAR(50),
    RatecodeID VARCHAR(50),
    store_and_fwd_flag VARCHAR(50),
    PULocationID VARCHAR(50),
    DOLocationID VARCHAR(50),
    payment_type VARCHAR(50),
    fare_amount VARCHAR(50),
    extra VARCHAR(50),
    mta_tax VARCHAR(50),
    tip_amount VARCHAR(50),
    tolls_amount VARCHAR(50),
    improvement_surcharge VARCHAR(50),
    total_amount VARCHAR(50),
    congestion_surcharge VARCHAR(50),
);--create staging table that loads the data from the chosen csv file
--IMPORT CSV
LOAD DATA LOCAL INFILE 'path/to/taxi_trip_data.csv'
INTO TABLE StagingTable
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
SELECT COUNT(*) FROM StagingTable; --check the number of records loaded into the staging table
--CLEAN UP DATA
UPDATE StagingTable
SET tpep_pickup_datetime  = REPLACE(TRIM(tpep_pickup_datetime),  '  ', ' '),
tpep_dropoff_datetime = REPLACE(TRIM(tpep_dropoff_datetime), '  ', ' '),
congestion_surcharge  = TRIM(REPLACE(congestion_surcharge, '\r', ''));
DELETE FROM StagingTable 
WHERE tpep_pickup_datetime IS NULL OR tpep_pickup_datetime  = '' OR
tpep_dropoff_datetime IS NULL ORtpep_dropoff_datetime = '' OR
PULocationID IS NULL OR PULocationID = '' OR
DOLocationID IS NULL OR DOLocationID = '' OR
trip_distance IS NULL OR trip_distance = '' OR
fare_amount IS NULL OR fare_amount = '' OR
total_amount IS NULL OR total_amount = '';--REMOVING EMPTY OR NULL ROWS
--POPULATE TABLES
INSERT INTO VENDOR(vendor_id, vendor_name)
SELECT DISTINCT CAST (VendorID AS UNSIGNED),'UNKNOWN'
FROM StagingTable
WHERE VendorID <>'';
UPDATE VENDOR SET vendor_name = CASE VendorID
    WHEN '1' THEN 'Creative Mobile Technologies, LLC'
    WHEN '2' THEN 'VeriFone Inc.'
    ELSE 'UNKNOWN'
END;

INSERT INTO RATE_CODE (rate_code_id, rate_code_description)
SELECT DISTINCT CAST (RatecodeID AS UNSIGNED), 'UNKNOWN'
FROM StagingTable
WHERE RatecodeID <>'';
UPDATE RATE_CODE SET rate_code_description = CASE RatecodeID
    WHEN '1' THEN 'Standard rate'
    WHEN '2' THEN 'JFK'
    WHEN '3' THEN 'Newark'
    WHEN '4' THEN 'Nassau or Westchester'
    WHEN '5' THEN 'Negotiated fare'
    WHEN '6' THEN 'Group ride'
    ELSE 'UNKNOWN'
END;

INSERT INTO PAYMENT_TYPE (payment_type_id, payment_type_description)
SELECT DISTINCT CAST (payment_type AS UNSIGNED), 'UNKNOWN'
FROM StagingTable
WHERE payment_type <>'';
UPDATE PAYMENT_TYPE SET payment_type_description = CASE payment_type_id
    WHEN '1' THEN 'Credit card'
    WHEN '2' THEN 'Cash'
    WHEN '3' THEN 'No charge'
    WHEN '4' THEN 'Dispute'
    WHEN '5' THEN 'Unknown'
    WHEN '6' THEN 'Voided trip'
    ELSE 'UNKNOWN'
END;

INSERT INTO LOCATION (location_id)
SELECT CAST (PULocationID AS UNSIGNED) FROM StagingTable
UNION --needs every ID from pickup and dropoff. removes duplicates
SELECT CAST (DOLocationID AS UNSIGNED) FROM StagingTable

INSERT INTO TRIP (trip_id, vendor_id,ratecode_id, passenger_count, trip_distance, store_and_fwd_flag)
SELECT staging_id,
CAST (NULLIF(VendorID, '')AS UNSIGNED),
CAST(NULLIF(RatecodeID, '')AS UNSIGNED),
CAST(NULLIF(passenger_count, '')AS UNSIGNED),
CAST(NULLIF(trip_distance, '')AS DECIMAL(10,2)),
NULLIF(store_and_fwd_flag, '')
FROM StagingTable;

INSERT INTO TRIP_STOP(trip_id, stop_type, stop_datetime, location_id)
SELECT staging_id, 'P',
STR_TO_DATE(tpep_pickup_datetime,' %m/%d/%Y %r'),
CAST(PULocationID AS UNSIGNED)
FROM StagingTable;
INSERT INTO TRIP_STOP(trip_id, stop_type, stop_datetime, location_id)
SELECT staging_id, 'D',
STR_TO_DATE(tpep_dropoff_datetime,' %m/%d/%Y %r'),
CAST(DOLocationID AS UNSIGNED)
FROM StagingTable;

INSERT INTO PAYMENT(payment_id,trip_id,payment_type_id, fare_amount,extra, mta_tax, tip_amount, tolls_amount,improvement_surcharge, congestion_surcharge, total_amount)
SELECT staging_id, staging_id,
CAST(NULLIF(payment_type,'')AS UNSIGNED),
CAST(COALESCE(NULLIF(fare_amount,''),0) AS DECIMAL(10,2)),
CAST(COALESCE(NULLIF(extra,''),0) AS DECIMAL(10,2)),
CAST(COALESCE(NULLIF(mta_tax,''),0) AS DECIMAL(10,2)),
CAST(COALESCE(NULLIF(tip_amount,''),0) AS DECIMAL(10,2)),
CAST(COALESCE(NULLIF(tolls_amount,''),0) AS DECIMAL(10,2)),
CAST(COALESCE(NULLIF(improvement_surcharge,''),0) AS DECIMAL(10,2)),
CAST(COALESCE(NULLIF(congestion_surcharge,''),0) AS DECIMAL(10,2)),
CAST(total_amount AS DECIMAL(10,2))
FROM StaginTable;
--VALIDATE DATA
SELECT 'staging' AS tbl, COUNT(*) FROM StagingTable
UNION ALL SELECT 'trip', COUNT(*) FROM TRIP
UNION ALL SELECT 'trip_stop', COUNT(*) FROM TRIP_STOP
UNION ALL SELECT 'payment', COUNT(*) FROM PAYMENT
UNION ALL SELECT 'vendor', COUNT(*) FROM VENDOR
UNION ALL SELECT 'location', COUNT(*) FROM LOCATION;
--ORPHAN CHECK (SHOULD RETURN 0)
SELECT COUNT(*) FROM TRIP t LEFT JOIN VENDOR v ON t.vendor_id = v.vendor_id 
WHERE t.vendor_id IS NOT NULL AND v.vendor_id IS NULL;
SELECT COUNT(*) FROM TRIP_STOP ts LEFT JOIN LOCATION 1 ON ts.location_id = l.location_id
WHERE  l.location_id IS NULL;
--SPOT CHECK
SELECTSELECT t.trip_id, v.vendor_name, ts.stop_type, ts.stop_datetime, p.total_amount
FROM TRIP t
JOIN VENDOR v ON t.vendor_id = v.vendor_id
JOIN TRIP_STOP ts ON t.trip_id = ts.trip_id
JOIN PAYMENT p ON t.trip_id = p.trip_id
WHERE t.trip_id = 1;