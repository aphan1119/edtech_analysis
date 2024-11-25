-- Create tables and import data from CSV files
-- Table: lead_details
CREATE TABLE IF NOT EXISTS lead_details (
	lead_id VARCHAR(10) NOT NULL,
	age INT,
	gender VARCHAR(6),
	current_city VARCHAR,
	current_education VARCHAR,
	parent_occupation VARCHAR,
	generated_source VARCHAR,
	PRIMARY KEY (lead_id)
);

COPY lead_details
FROM 'C:\Users\aphan\OneDrive\Desktop\Study\EdTech_Analysis\leads_basic_details.csv'
DELIMITER ','
CSV HEADER;

-- Table: sales_manager
CREATE TABLE IF NOT EXISTS sales_manager (
	jnr_sm_id VARCHAR(10) NOT NULL,
	snr_sm_id VARCHAR(10) NOT NULL,
	PRIMARY KEY (jnr_sm_id)
);

COPY sales_manager
FROM 'C:\Users\aphan\OneDrive\Desktop\Study\EdTech_Analysis\sales_manager.csv'
DELIMITER ','
CSV HEADER;

-- Table: sales_manager_assigned
CREATE TABLE IF NOT EXISTS sales_manager_assigned (
	snr_sm_id VARCHAR(10) NOT NULL,
	jnr_sm_id VARCHAR(10) NOT NULL,
	assigned_date DATE,
	cycle INT,
	lead_id VARCHAR(10) NOT NULL,
	FOREIGN KEY (jnr_sm_id) REFERENCES sales_manager(jnr_sm_id),
	FOREIGN KEY (lead_id) REFERENCES lead_details(lead_id)
);

COPY sales_manager_assigned
FROM 'C:\Users\aphan\OneDrive\Desktop\Study\EdTech_Analysis\sales_managers_assigned_leads_details.csv'
DELIMITER ','
CSV HEADER;

-- Table: interaction_details
CREATE TABLE IF NOT EXISTS interaction_details (
	jnr_sm_id VARCHAR(10) NOT NULL,
	lead_id VARCHAR(10) NOT NULL,
	lead_stage VARCHAR(20) NOT NULL,
	call_date DATE,
	call_status VARCHAR(20),
	call_reason VARCHAR,
	FOREIGN KEY (jnr_sm_id) REFERENCES sales_manager(jnr_sm_id),
	FOREIGN KEY (lead_id) REFERENCES lead_details(lead_id)
);

COPY interaction_details
FROM 'C:\Users\aphan\OneDrive\Desktop\Study\EdTech_Analysis\leads_interaction_details.csv'
DELIMITER ','
CSV HEADER;

-- Table: demo_watched_details
CREATE TABLE IF NOT EXISTS demo_watched_details (
	lead_id VARCHAR(10) NOT NULL,
	watched_date DATE,
	demo_language VARCHAR(20),
	watched_percentage INT,
	FOREIGN KEY (lead_id) REFERENCES lead_details(lead_id)
);

COPY demo_watched_details
FROM 'C:\Users\aphan\OneDrive\Desktop\Study\EdTech_Analysis\leads_demo_watched_details.csv'
DELIMITER ','
CSV HEADER;

-- Table: not_interested_reason
CREATE TABLE IF NOT EXISTS not_interested_reason (
	lead_id VARCHAR(10) NOT NULL,
	reason_not_interested_in_demo VARCHAR,
	reason_not_interested_to_consider VARCHAR,
	reason_not_interested_to_convert VARCHAR,
	FOREIGN KEY (lead_id) REFERENCES lead_details(lead_id)
);

COPY not_interested_reason
FROM 'C:\Users\aphan\OneDrive\Desktop\Study\EdTech_Analysis\leads_reasons_for_no_interest.csv'
DELIMITER ','
CSV HEADER;