PRAGMA foreign_keys=OFF;
BEGIN TRANSACTION;
CREATE TABLE resumes (
	id INTEGER NOT NULL, 
	resume_id VARCHAR NOT NULL, 
	content TEXT NOT NULL, 
	content_type VARCHAR NOT NULL, 
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (resume_id)
);
CREATE TABLE users (
	id INTEGER NOT NULL, 
	email VARCHAR NOT NULL, 
	name VARCHAR NOT NULL, 
	PRIMARY KEY (id)
);
CREATE TABLE processed_resumes (
	resume_id VARCHAR NOT NULL, 
	personal_data JSON NOT NULL, 
	experiences JSON, 
	projects JSON, 
	skills JSON, 
	research_work JSON, 
	achievements JSON, 
	education JSON, 
	extracted_keywords JSON, 
	processed_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, 
	PRIMARY KEY (resume_id), 
	FOREIGN KEY(resume_id) REFERENCES resumes (resume_id) ON DELETE CASCADE
);
CREATE TABLE jobs (
	id INTEGER NOT NULL, 
	job_id VARCHAR NOT NULL, 
	resume_id VARCHAR NOT NULL, 
	content TEXT NOT NULL, 
	created_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (job_id), 
	FOREIGN KEY(resume_id) REFERENCES resumes (resume_id)
);
CREATE TABLE processed_jobs (
	job_id VARCHAR NOT NULL, 
	job_title VARCHAR NOT NULL, 
	company_profile TEXT, 
	location VARCHAR, 
	date_posted VARCHAR, 
	employment_type VARCHAR, 
	job_summary TEXT NOT NULL, 
	key_responsibilities JSON, 
	qualifications JSON, 
	compensation_and_benfits JSON, 
	application_info JSON, 
	extracted_keywords JSON, 
	processed_at DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, 
	PRIMARY KEY (job_id), 
	FOREIGN KEY(job_id) REFERENCES jobs (job_id) ON DELETE CASCADE
);
CREATE TABLE job_resume (
	processed_job_id VARCHAR NOT NULL, 
	processed_resume_id VARCHAR NOT NULL, 
	PRIMARY KEY (processed_job_id, processed_resume_id), 
	FOREIGN KEY(processed_job_id) REFERENCES processed_jobs (job_id), 
	FOREIGN KEY(processed_resume_id) REFERENCES processed_resumes (resume_id)
);
CREATE INDEX ix_resumes_id ON resumes (id);
CREATE INDEX ix_resumes_created_at ON resumes (created_at);
CREATE UNIQUE INDEX ix_users_email ON users (email);
CREATE INDEX ix_users_id ON users (id);
CREATE INDEX ix_processed_resumes_processed_at ON processed_resumes (processed_at);
CREATE INDEX ix_processed_resumes_resume_id ON processed_resumes (resume_id);
CREATE INDEX ix_jobs_created_at ON jobs (created_at);
CREATE INDEX ix_jobs_id ON jobs (id);
CREATE INDEX ix_processed_jobs_processed_at ON processed_jobs (processed_at);
CREATE INDEX ix_processed_jobs_job_id ON processed_jobs (job_id);
COMMIT;
