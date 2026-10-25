USE taxi_db;
-- TABLES CONTAIN DATA
SELECT 'staging' AS tbl, COUNT(*) AS row_count FROM StagingTable
UNION ALL SELECT 'vendor', COUNT(*) FROM VENDOR
UNION ALL SELECT 'rate_code', COUNT(*) FROM RATE_CODE
UNION ALL SELECT 'payment_type', COUNT(*) FROM PAYMENT_TYPE
UNION ALL SELECT 'location', COUNT(*) FROM LOCATION
UNION ALL SELECT 'trip', COUNT(*) FROM TRIP
UNION ALL SELECT 'trip_stop', COUNT(*) FROM TRIP_STOP
UNION ALL SELECT 'payment', COUNT(*) FROM PAYMENT;
SELECT * FROM VENDOR;
SELECT * FROM RATE_CODE;
SELECT * FROM PAYMENT_TYPE;
SELECT * FROM LOCATION LIMIT 10;
SELECT * FROM TRIP LIMIT 10;
SELECT * FROM TRIP_STOP LIMIT 10;
SELECT * FROM PAYMENT LIMIT 10;
-- PRIMARY KEYS POPULATED AND UNIQUE 
SELECT 'TRIP' AS tbl, COUNT(*) AS total, COUNT(DISTINCT trip_id) AS distinct_pk,SUM(trip_id IS NULL) AS null_pk FROM TRIP
UNION ALL
SELECT 'PAYMENT', COUNT(*), COUNT(DISTINCT payment_id), SUM(payment_id IS NULL) FROM PAYMENT
UNION ALL
SELECT 'TRIP_STOP', COUNT(*), COUNT(DISTINCT trip_id, stop_type), SUM(trip_id IS NULL OR stop_type IS NULL) FROM TRIP_STOP
UNION ALL
SELECT 'LOCATION', COUNT(*), COUNT(DISTINCT location_id), SUM(location_id IS NULL) FROM LOCATION;
-- FOREIGN KEYS POPULATED 
SELECT 'trip->vendor' AS fk_check, COUNT(*) AS orphans FROM TRIP t
  LEFT JOIN VENDOR v ON t.vendor_id = v.vendor_id
  WHERE t.vendor_id IS NOT NULL AND v.vendor_id IS NULL
UNION ALL
SELECT 'trip->rate_code', COUNT(*) FROM TRIP t
  LEFT JOIN RATE_CODE r ON t.ratecode_id = r.ratecode_id
  WHERE t.ratecode_id IS NOT NULL AND r.ratecode_id IS NULL
UNION ALL
SELECT 'trip_stop->trip', COUNT(*) FROM TRIP_STOP ts
  LEFT JOIN TRIP t ON ts.trip_id = t.trip_id WHERE t.trip_id IS NULL
UNION ALL
SELECT 'trip_stop->location', COUNT(*) FROM TRIP_STOP ts
  LEFT JOIN LOCATION l ON ts.location_id = l.location_id WHERE l.location_id IS NULL
UNION ALL
SELECT 'payment->trip', COUNT(*) FROM PAYMENT p
  LEFT JOIN TRIP t ON p.trip_id = t.trip_id WHERE t.trip_id IS NULL
UNION ALL
SELECT 'payment->payment_type', COUNT(*) FROM PAYMENT p
  LEFT JOIN PAYMENT_TYPE pt ON p.payment_type_id = pt.payment_type_id
  WHERE p.payment_type_id IS NOT NULL AND pt.payment_type_id IS NULL;
-- EXPECTED RECORD COUNTS 
SELECT 'trip = staging rows' AS test,
(SELECT COUNT(*) FROM StagingTable) AS expected,
(SELECT COUNT(*) FROM TRIP) AS actual
UNION ALL
SELECT 'trip_stop = 2 x staging rows',
(SELECT 2 * COUNT(*) FROM StagingTable), (SELECT COUNT(*) FROM TRIP_STOP)
UNION ALL
SELECT 'payment = staging rows',
(SELECT COUNT(*) FROM StagingTable), (SELECT COUNT(*) FROM PAYMENT)
UNION ALL
SELECT 'distinct vendors',
(SELECT COUNT(DISTINCT VendorID) FROM StagingTable WHERE VendorID <> ''),
(SELECT COUNT(*) FROM VENDOR)
UNION ALL
SELECT 'distinct locations',
(SELECT COUNT(*) FROM (SELECT PULocationID AS id FROM StagingTable
  UNION SELECT DOLocationID FROM StagingTable) x),
(SELECT COUNT(*) FROM LOCATION);
-- ORIGINAL INFORMATION PRESERVED
SELECT (SELECT SUM(CAST(total_amount AS DECIMAL(10,2))) FROM StagingTable) AS staging_total,
       (SELECT SUM(total_amount) FROM PAYMENT) AS payment_total,
       (SELECT SUM(CAST(trip_distance AS DECIMAL(10,2))) FROM StagingTable) AS staging_distance,
       (SELECT SUM(trip_distance) FROM TRIP) AS trip_distance_total;
-- Rebuild the original flat row from the normalized tables (should return 0 mismatches)
SELECT COUNT(*) AS mismatched_rows
FROM StagingTable s
JOIN TRIP t        ON t.trip_id = s.staging_id
JOIN TRIP_STOP pu  ON pu.trip_id = t.trip_id AND pu.stop_type = 'P'
JOIN TRIP_STOP do_ ON do_.trip_id = t.trip_id AND do_.stop_type = 'D'
JOIN PAYMENT p     ON p.trip_id = t.trip_id
WHERE pu.location_id <> CAST(s.PULocationID AS UNSIGNED)
   OR do_.location_id <> CAST(s.DOLocationID AS UNSIGNED)
   OR p.total_amount <> CAST(s.total_amount AS DECIMAL(10,2))
   OR t.trip_distance <> CAST(s.trip_distance AS DECIMAL(10,2));
-- Readable sample of the reconstructed data
SELECT t.trip_id, v.vendor_name, rc.rate_description, pu.stop_datetime AS pickup_time,
       do_.stop_datetime AS dropoff_time, pu.location_id AS pu_loc, do_.location_id AS do_loc,
       t.trip_distance, pt.payment_description, p.total_amount
FROM TRIP t
LEFT JOIN VENDOR v ON v.vendor_id = t.vendor_id
LEFT JOIN RATE_CODE rc ON rc.ratecode_id = t.ratecode_id
JOIN TRIP_STOP pu  ON pu.trip_id = t.trip_id AND pu.stop_type = 'P'
JOIN TRIP_STOP do_ ON do_.trip_id = t.trip_id AND do_.stop_type = 'D'
JOIN PAYMENT p ON p.trip_id = t.trip_id
LEFT JOIN PAYMENT_TYPE pt ON pt.payment_type_id = p.payment_type_id
LIMIT 10;