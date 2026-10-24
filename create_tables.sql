CREATE TABLE VENDOR (
    vendor_id INT PRIMARY KEY,
    vendor_name VARCHAR(50) 
);

CREATE TABLE RATE_CODE (
    ratecode_id INT PRIMARY KEY,
    rate_description VARCHAR(50)
);

CREATE TABLE PAYMENT_TYPE (
    payment_type_id INT PRIMARY KEY,
    payment_description VARCHAR(50)
);

CREATE TABLE LOCATION (
    location_id INT PRIMARY KEY
);

CREATE TABLE TRIP (
    trip_id INT PRIMARY KEY,
    vendor_id INT,
    CONSTRAINT fk_vendor FOREIGN KEY (vendor_id) REFERENCES VENDOR(vendor_id),
    ratecode_id INT,
    CONSTRAINT fk_ratecode_id FOREIGN KEY (ratecode_id) REFERENCES RATE_CODE(ratecode_id),
    passenger_count INT
);