-- DATA CLEANING (lead_details table)
-- CHECK DUPLICATES
SELECT
	*,
	COUNT(*)
FROM lead_details
GROUP BY lead_id
HAVING COUNT(*) > 1; -- no duplicates

-- CHECK OUTLIERS
SELECT
	age_quartile,
	max(age)
FROM
(
 SELECT
	lead_id,
	age,
	NTILE(4) OVER (ORDER BY age) AS age_quartile
 FROM lead_details
)
WHERE age_quartile = 1 OR age_quartile = 3
GROUP BY age_quartile;
-- 1.5*4=6
-- lower threshold: 18-6 = 12
-- upper threshold: 24+6 = 30

SELECT
	lead_id,
	age
FROM lead_details
WHERE age < 12 OR age > 30;
-- there are 2 record shows lead age of 116 and 211, which could be a typo from whoever entered the data.
-- replace these records with MEDIAN age

SELECT AVG(age) AS median	-- Find Median AGE value: 21
FROM
(
	SELECT 
		lead_id,
		age,
		ROW_NUMBER() OVER(ORDER BY age ASC, lead_id ASC) rowAsc,
		ROW_NUMBER() OVER(ORDER BY age DESC, lead_id DESC) rowDesc
	FROM lead_details
)
WHERE rowAsc in (rowDesc, rowDesc-1, rowDesc+1);

UPDATE lead_details 		-- Outliers imputation
SET age = '21'
WHERE age IN
(
	SELECT age
	FROM lead_details
	WHERE age < 12 OR age > 30
);

-- CHECK UNIQUE VALUES (NO MISSPELLING)
SELECT
	generated_source,
	COUNT(generated_source)
FROM lead_details
GROUP BY generated_source;
------------------------------------------------------------------------
-- DATA CLEANING (demo_watched_details table)
-- CHECK DUPLICATES
SELECT
	*,
	COUNT(*)
FROM demo_watched_details
GROUP BY lead_id, watched_date, demo_language, watched_percentage
HAVING COUNT(*) > 1; -- no duplicates

-- CHECK UNIQUE VALUES (NO MISSPELLING)
SELECT
	demo_language,
	COUNT(demo_language)
FROM demo_watched_details
GROUP BY demo_language;

-- CHECK ERRORS
SELECT watched_percentage
FROM demo_watched_details
WHERE watched_percentage < 0 OR watched_percentage > 100;

SELECT ROUND(AVG(watched_percentage)) AS median	-- Find Median watched_percentage value: 56
FROM
(
	SELECT 
		lead_id,
		watched_percentage,
		ROW_NUMBER() OVER(ORDER BY watched_percentage ASC, lead_id ASC) rowAsc,
		ROW_NUMBER() OVER(ORDER BY watched_percentage DESC, lead_id DESC) rowDesc
	FROM demo_watched_details
)
WHERE rowAsc in (rowDesc, rowDesc-1, rowDesc+1);

UPDATE demo_watched_details 		-- Outliers imputation (replace with MEDIAN)
SET watched_percentage = '56'
WHERE watched_percentage IN
(
	SELECT watched_percentage
	FROM demo_watched_details
	WHERE watched_percentage < 0 OR watched_percentage > 100
);
------------------------------------------------------------------------
-- DATA CLEANING (interaction_details table)
-- CHECK DUPLICATES
SELECT
	*,
	COUNT(*)
FROM interaction_details
GROUP BY jnr_sm_id, lead_id, lead_stage, call_date, call_status, call_reason
HAVING COUNT(*) > 1
ORDER BY lead_id;
-- even though there are many duplicates, we're going to keep all of them,
-- but just take into account the last call for the same call reason.
-- because some call happens on the same day could be because customer did not pick up so sm try to call again same day,
-- or customer pick up but then askede sm to call again later same day.

-- CHECK UNIQUE VALUES (NO MISSPELLING)
SELECT
	call_reason,
	COUNT(call_reason)
FROM interaction_details
GROUP BY call_reason;
------------------------------------------------------------------------
-- DATA CLEANING (not_interested_reason table)
-- CHECK DUPLICATES
SELECT
	*,
	COUNT(*)
FROM not_interested_reason
GROUP BY lead_id, reason_not_interested_in_demo, reason_not_interested_to_consider, reason_not_interested_to_convert
HAVING COUNT(*) > 1;	-- no duplicates

-- CHECK NULL VALUES (not interest needs to have at least 1 reason - all 3 values can't be null at the same time)
SELECT *
FROM not_interested_reason
WHERE reason_not_interested_in_demo IS NULL
AND reason_not_interested_to_consider IS NULL
AND reason_not_interested_to_convert IS NULL; -- all good

-- CHECK UNIQUE VALUES (NO MISSPELLING)
SELECT
	reason_not_interested_in_demo,
	COUNT(reason_not_interested_in_demo)
FROM not_interested_reason
GROUP BY reason_not_interested_in_demo; -- fix different entry "Can't afford" and "Cannot afford" 

UPDATE not_interested_reason			-- change value
SET reason_not_interested_in_demo = 'Can''t afford'
WHERE reason_not_interested_in_demo = 'Cannot afford';
------------------------------------------------------------------------
-- DATA CLEANING (sales_manager table)
SELECT DISTINCT snr_sm_id, jnr_sm_id
FROM sales_manager_assigned
WHERE snr_sm_id = 'SNR501MG';

SELECT DISTINCT snr_sm_id, jnr_sm_id
FROM sales_manager
WHERE snr_sm_id = 'SNR501MG';
-- there is a data inaccuracy between tables, but it is stated that each snr_sm has 4 jnr_sm, therefore, a record in sales_manager
-- table is incorrect.
-- fix record:
UPDATE sales_manager
SET snr_sm_id = 'SNR504MG'
WHERE jnr_sm_id = 'JNR1016MG';
