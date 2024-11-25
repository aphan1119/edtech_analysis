-- 1. Which source generate the most leads? Which generate the least?
SELECT
	generated_source,
	COUNT(generated_source) AS count_source,
	COUNT(generated_source)*100/(SELECT COUNT(*) FROM lead_details) AS source_perc
FROM lead_details
GROUP BY generated_source
ORDER BY count_source DESC;
-- Most leads 24% were generated from social media (ads), while EdTech website only generate 16% of leads.

-- 2. Rank watch demo percentage. if majority not even finish half the demo
SELECT
	percentage,
	COUNT(percentage),
	COUNT(percentage)*100/(SELECT COUNT(*) FROM demo_watched_details) AS percentage_watched
FROM
(SELECT
	lead_id,
	CASE
		WHEN watched_percentage >= 0 AND watched_percentage <= 20 THEN '0-20'
		WHEN watched_percentage > 20 AND watched_percentage <= 40 THEN '21-40'
		WHEN watched_percentage > 40 AND watched_percentage <= 60 THEN '41-60'
		WHEN watched_percentage > 60 AND watched_percentage <= 80 THEN '61-80'
		ELSE '81-100'
	END AS percentage
FROM demo_watched_details)
GROUP BY percentage
ORDER BY percentage ASC;
-- Majority of leads finished 61-80% of the demo. Only 13% finished 81-100% the demo.

-- 3. Language watched by city
SELECT
	ld.current_city,
	dw.demo_language,
	COUNT(dw.demo_language),
	ROUND(COUNT(dw.demo_language)*100/SUM(COUNT(dw.demo_language)) OVER(PARTITION BY ld.current_city),2) AS percentage_within_city
FROM demo_watched_details dw
JOIN lead_details ld
ON dw.lead_id = ld.lead_id
GROUP BY ld.current_city, dw.demo_language
ORDER BY ld.current_city, COUNT(dw.demo_language) DESC;
-- The most viewed language in the demo of all cities is English, followed by Telugu and Hindi.

-- 4. What is the successful conversion rate
SELECT
	COUNT(call_reason)*100/(SELECT COUNT(*) FROM lead_details) AS successful_conversion_rate
FROM interaction_details
WHERE call_reason = 'successful_conversion';
-- Successful conversion rate is only 17% (successful/total*100)

-- 5. Successful converted- characteristic of these leads?
WITH converted AS
(SELECT *
FROM lead_details
WHERE lead_id IN
(
SELECT DISTINCT lead_id
FROM interaction_details
WHERE call_reason = 'successful_conversion'
))

SELECT
	generated_source,
	COUNT(generated_source),
	COUNT(generated_source)*100/(SELECT COUNT(*) FROM converted) AS percentage
FROM converted
GROUP BY 1
ORDER BY 3 DESC;
-- 67% of successful conversion are female, only 32% are male.
-- 23% successful conversion are people come from Bengaluru, 23% from Visakhapatnam, 20% from Hyderabad.
-- 40% of successful conversion are people with current education of B.Tech, then 29% of people who are currently looking for a job.
-- 32% of successful conversion are people who has parent working in Business field, 28% are Government Employee.
-- 29% of successful conversion are people come from source of email marketing, 26% from social media.

-- 6. Follow-up for conversion- how many end up not converting, why?
WITH followup AS
(SELECT *
FROM interaction_details
WHERE call_reason = 'followup_for_conversion'
ORDER BY lead_id ASC)

SELECT
	reason_not_interested_to_convert,
	COUNT(reason_not_interested_to_convert) AS number_leads
FROM
(
SELECT DISTINCT
	nir.lead_id,
	nir.reason_not_interested_to_convert
FROM followup fl
INNER JOIN not_interested_reason nir
ON fl.lead_id = nir.lead_id
ORDER BY nir.reason_not_interested_to_convert, nir.lead_id
)
GROUP BY 1
ORDER BY number_leads DESC;
-- Out of 102 leads were follow up for conversion and a total of 189 followup attempts both successful and unsuccessful,
-- 40 leads ended up not converting.
-- WHY?

-- 7. Manager failed to reach out rate
-- lead interested but manager did not reach out after certain stage → lead drop
WITH ranked AS
(SELECT 
	ids.lead_id,
	ids.call_date,
	ids.call_reason,
	ROW_NUMBER() OVER(PARTITION BY ids.lead_id) AS rn
FROM interaction_details ids
LEFT JOIN not_interested_reason nir
ON ids.lead_id = nir.lead_id
WHERE call_date =
(
SELECT MAX(call_date)
FROM interaction_details ids2
WHERE ids.lead_id = ids2.lead_id
)
AND nir.lead_id IS NULL)

SELECT
	lead_id,
	call_date,
	call_reason
FROM ranked
WHERE rn =
(
SELECT MAX(rn)
FROM ranked AS r
WHERE r.lead_id = ranked.lead_id
)
AND call_reason != 'successful_conversion';
-- 4 leads who last interaction with manager stopped midway- no rejection but also no conversion, manager failed to reach out again.

-- 8. Converted rate for each junior & senior manager? (each Sr assigned with 4 Jr)
-- converted rate for each jr manager?
WITH converted AS
(
SELECT
	jnr_sm_id,
	COUNT(lead_id) AS converted_number
FROM interaction_details
WHERE call_reason = 'successful_conversion'
GROUP BY jnr_sm_id
ORDER BY jnr_sm_id ASC),

total AS
(SELECT
	jnr_sm_id,
	COUNT(lead_id) AS total_number
FROM sales_manager_assigned
GROUP BY jnr_sm_id
ORDER BY jnr_sm_id ASC)

SELECT
	total.jnr_sm_id,
	converted.converted_number*100/total.total_number
FROM total
LEFT JOIN converted
ON total.jnr_sm_id = converted.jnr_sm_id;

-- converted rate for each SNR manager?
WITH converted AS	-- senior manager and successful converted leads
(
SELECT
	sm.snr_sm_id,
	COUNT(ids.lead_id) AS converted_number
FROM interaction_details ids
RIGHT JOIN sales_manager sm
ON ids.jnr_sm_id = sm.jnr_sm_id
WHERE ids.call_reason = 'successful_conversion'
GROUP BY sm.snr_sm_id
ORDER BY sm.snr_sm_id ASC),

total AS			-- senior manager and total leads assigned
(SELECT
	snr_sm_id,
	COUNT(lead_id) AS total_number
FROM sales_manager_assigned
GROUP BY snr_sm_id
ORDER BY snr_sm_id ASC)

SELECT
	total.snr_sm_id,
	converted.converted_number*100/total.total_number AS conversion_rate
FROM total
LEFT JOIN converted
ON total.snr_sm_id = converted.snr_sm_id;

-- 9. drop out of which stage percentage
SELECT 
	COUNT(reason_not_interested_in_demo)*100/(SELECT COUNT(*) FROM not_interested_reason) AS no_demo_perc,
	COUNT(reason_not_interested_to_consider)*100/(SELECT COUNT(*) FROM not_interested_reason) AS no_consider_perc,
	COUNT(reason_not_interested_to_convert)*100/(SELECT COUNT(*) FROM not_interested_reason) AS no_convert_perc
FROM not_interested_reason;
-- most leads drop from the process since the beginning of the process- after watching the demo.

-- 10. reason being “can’t afford” - if majority then maybe special offer?
SELECT
	'not_intersted_in_demo' AS reason,
	COUNT(CASE WHEN reason_not_interested_in_demo = 'Can''t afford' THEN 1 END) AS cant_afford_count,
	COUNT(reason_not_interested_in_demo) AS total_count,
	COUNT(CASE WHEN reason_not_interested_in_demo = 'Can''t afford' THEN 1 END)*100/COUNT(reason_not_interested_in_demo) AS cant_afford_perc 
FROM not_interested_reason
WHERE reason_not_interested_in_demo IS NOT null

UNION ALL

SELECT
	'not_intersted_to_consider' AS reason,
	COUNT(CASE WHEN reason_not_interested_to_consider = 'Can''t afford' THEN 1 END) AS cant_afford_count,
	COUNT(reason_not_interested_to_consider) AS total_count,
	COUNT(CASE WHEN reason_not_interested_to_consider = 'Can''t afford' THEN 1 END)*100/COUNT(reason_not_interested_to_consider) AS cant_afford_perc 
FROM not_interested_reason
WHERE reason_not_interested_to_consider IS NOT null

UNION ALL

SELECT
	'not_intersted_to_convert' AS reason,
	COUNT(CASE WHEN reason_not_interested_to_convert = 'Can''t afford' THEN 1 END) AS cant_afford_count,
	COUNT(reason_not_interested_to_convert) AS total_count,
	COUNT(CASE WHEN reason_not_interested_to_convert = 'Can''t afford' THEN 1 END)*100/COUNT(reason_not_interested_to_convert) AS cant_afford_perc 
FROM not_interested_reason
WHERE reason_not_interested_to_convert IS NOT null;
-- Since most number of people (40%) who dropped out from considering the course is due to the price,
-- we can reach out to these people to offer some discount or offers to keep them interested.

-- 11. “will join in final year” - reach out in final year to remind these leads.
SELECT
	sma.jnr_sm_id,
	nir.lead_id,
	ld.current_education,
	nir.reason_not_interested_in_demo,
	nir.reason_not_interested_to_consider,
	nir.reason_not_interested_to_convert
FROM not_interested_reason nir
INNER JOIN lead_details ld
ON nir.lead_id = ld.lead_id
LEFT JOIN sales_manager_assigned sma
ON ld.lead_id = sma.lead_id
WHERE reason_not_interested_in_demo = 'Will join in final year'
OR reason_not_interested_to_consider = 'Will join in final year'
OR reason_not_interested_to_convert = 'Will join in final year';
-- People who dropped out of the progress reason being 'will join in final year', reach out to them during final year to remind them
