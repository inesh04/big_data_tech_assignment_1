DROP DATABASE IF EXISTS taxi_db;
CREATE DATABASE taxi_db;
USE taxi_db;

CREATE TABLE VENDOR (
    vendor_id INT PRIMARY KEY,
    vendor_name VARCHAR(50) NOT NULL
);

CREATE TABLE RATE_CODE (
    ratecode_id INT PRIMARY KEY,
    rate_description VARCHAR(50) NOT NULL
);

CREATE TABLE PAYMENT_TYPE (
    payment_type_id INT PRIMARY KEY,
    payment_description VARCHAR(50) NOT NULL
);

CREATE TABLE LOCATION (
    location_id INT PRIMARY KEY
);

CREATE TABLE TRIP (
    trip_id INT PRIMARY KEY,
    vendor_id INT,
    ratecode_id INT,
    passenger_count INT,
    trip_distance DECIMAL(10, 2) NOT NULL,
    store_and_fwd_flag CHAR(1),
    CONSTRAINT fk_vendor FOREIGN KEY (vendor_id) REFERENCES VENDOR(vendor_id),
    CONSTRAINT fk_ratecode_id FOREIGN KEY (ratecode_id) REFERENCES RATE_CODE(ratecode_id)
);

CREATE TABLE TRIP_STOP (
    trip_id INT,
    stop_type CHAR(1),
    stop_datetime DATETIME NOT NULL,
    location_id INT NOT NULL,
    PRIMARY KEY (trip_id, stop_type),
    CONSTRAINT fk_trip_id FOREIGN KEY (trip_id) REFERENCES TRIP(trip_id),
    CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES LOCATION(location_id)
);

CREATE TABLE PAYMENT (
    payment_id INT PRIMARY KEY,
    trip_id INT NOT NULL UNIQUE,
    payment_type_id INT,
    fare_amount DECIMAL(10, 2) NOT NULL,
    extra DECIMAL(10, 2) NOT NULL,
    mta_tax DECIMAL(10, 2) NOT NULL,
    tip_amount DECIMAL(10, 2) NOT NULL,
    tolls_amount DECIMAL(10, 2) NOT NULL,
    improvement_surcharge DECIMAL(10, 2) NOT NULL,
    congestion_surcharge DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    CONSTRAINT fk_payment_trip FOREIGN KEY (trip_id) REFERENCES TRIP(trip_id),
    CONSTRAINT fk_payment_type_id FOREIGN KEY (payment_type_id) REFERENCES PAYMENT_TYPE(payment_type_id)
);