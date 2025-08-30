--
-- PostgreSQL database dump
--

\restrict WyqHcXxlpIYfWoHOBFcKUI0zJa9a2do9XpUGuYmEwHfnV0oDiwI5Wpbkw01e2TS

-- Dumped from database version 15.14 (Homebrew)
-- Dumped by pg_dump version 15.14 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: job_resume; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.job_resume (
    processed_job_id character varying NOT NULL,
    processed_resume_id character varying NOT NULL
);


ALTER TABLE public.job_resume OWNER TO szjason72;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.jobs (
    id integer NOT NULL,
    job_id character varying NOT NULL,
    resume_id character varying NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.jobs OWNER TO szjason72;

--
-- Name: jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.jobs_id_seq OWNER TO szjason72;

--
-- Name: jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.jobs_id_seq OWNED BY public.jobs.id;


--
-- Name: processed_jobs; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.processed_jobs (
    job_id character varying NOT NULL,
    job_title character varying NOT NULL,
    company_profile text,
    location character varying,
    date_posted character varying,
    employment_type character varying,
    job_summary text NOT NULL,
    key_responsibilities jsonb,
    qualifications jsonb,
    compensation_and_benfits jsonb,
    application_info jsonb,
    extracted_keywords jsonb,
    processed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.processed_jobs OWNER TO szjason72;

--
-- Name: processed_resumes; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.processed_resumes (
    resume_id character varying NOT NULL,
    personal_data jsonb NOT NULL,
    experiences jsonb,
    projects jsonb,
    skills jsonb,
    research_work jsonb,
    achievements jsonb,
    education jsonb,
    extracted_keywords jsonb,
    processed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.processed_resumes OWNER TO szjason72;

--
-- Name: resumes; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.resumes (
    id integer NOT NULL,
    resume_id character varying NOT NULL,
    content text NOT NULL,
    content_type character varying NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.resumes OWNER TO szjason72;

--
-- Name: resumes_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.resumes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.resumes_id_seq OWNER TO szjason72;

--
-- Name: resumes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.resumes_id_seq OWNED BY public.resumes.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying NOT NULL,
    name character varying NOT NULL
);


ALTER TABLE public.users OWNER TO szjason72;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO szjason72;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: jobs id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.jobs_id_seq'::regclass);


--
-- Name: resumes id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resumes ALTER COLUMN id SET DEFAULT nextval('public.resumes_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: job_resume; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.job_resume (processed_job_id, processed_resume_id) FROM stdin;
job_001	res_001
job_002	res_002
job_003	res_003
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.jobs (id, job_id, resume_id, content, created_at) FROM stdin;
1	job_001	res_001	Senior Software Engineer\nWe are looking for a Python developer...	2025-08-25 00:27:34.332964+08
2	job_002	res_002	Data Scientist\nJoin our AI team to build machine learning models...	2025-08-25 00:27:34.332964+08
3	job_003	res_003	Product Manager\nLead product development for our SaaS platform...	2025-08-25 00:27:34.332964+08
\.


--
-- Data for Name: processed_jobs; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.processed_jobs (job_id, job_title, company_profile, location, date_posted, employment_type, job_summary, key_responsibilities, qualifications, compensation_and_benfits, application_info, extracted_keywords, processed_at) FROM stdin;
job_001	Senior Software Engineer	\N	\N	\N	\N	Build scalable web applications	\N	["Python", "JavaScript", "5+ years"]	\N	\N	["software", "engineering", "python"]	2025-08-25 00:27:34.334656+08
job_002	Data Scientist	\N	\N	\N	\N	Develop machine learning models	\N	["Python", "ML", "PhD preferred"]	\N	\N	["data", "science", "ai"]	2025-08-25 00:27:34.334656+08
job_003	Product Manager	\N	\N	\N	\N	Lead product development	\N	["Product Management", "Leadership", "5+ years"]	\N	\N	["product", "management", "leadership"]	2025-08-25 00:27:34.334656+08
\.


--
-- Data for Name: processed_resumes; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.processed_resumes (resume_id, personal_data, experiences, projects, skills, research_work, achievements, education, extracted_keywords, processed_at) FROM stdin;
res_001	{"name": "John Doe", "email": "john@example.com"}	\N	\N	["Python", "JavaScript", "React"]	\N	\N	\N	["software", "engineering", "python"]	2025-08-25 00:27:34.333966+08
res_002	{"name": "Jane Smith", "email": "jane@example.com"}	\N	\N	["Python", "Machine Learning", "TensorFlow"]	\N	\N	\N	["data", "science", "ai"]	2025-08-25 00:27:34.333966+08
res_003	{"name": "Bob Wilson", "email": "bob@example.com"}	\N	\N	["Product Management", "Agile", "Leadership"]	\N	\N	\N	["product", "management", "leadership"]	2025-08-25 00:27:34.333966+08
\.


--
-- Data for Name: resumes; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.resumes (id, resume_id, content, content_type, created_at) FROM stdin;
1	res_001	John Doe\nSoftware Engineer\n5 years experience in Python, JavaScript...	text	2025-08-25 00:27:34.331118+08
2	res_002	Jane Smith\nData Scientist\nPhD in Computer Science...	text	2025-08-25 00:27:34.331118+08
3	res_003	Bob Wilson\nProduct Manager\n10 years experience in product development...	text	2025-08-25 00:27:34.331118+08
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.users (id, email, name) FROM stdin;
1	john.doe@example.com	John Doe
2	jane.smith@example.com	Jane Smith
3	bob.wilson@example.com	Bob Wilson
\.


--
-- Name: jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.jobs_id_seq', 3, true);


--
-- Name: resumes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.resumes_id_seq', 3, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- Name: job_resume job_resume_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_resume
    ADD CONSTRAINT job_resume_pkey PRIMARY KEY (processed_job_id, processed_resume_id);


--
-- Name: jobs jobs_job_id_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_job_id_key UNIQUE (job_id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: processed_jobs processed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.processed_jobs
    ADD CONSTRAINT processed_jobs_pkey PRIMARY KEY (job_id);


--
-- Name: processed_resumes processed_resumes_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.processed_resumes
    ADD CONSTRAINT processed_resumes_pkey PRIMARY KEY (resume_id);


--
-- Name: resumes resumes_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resumes
    ADD CONSTRAINT resumes_pkey PRIMARY KEY (id);


--
-- Name: resumes resumes_resume_id_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resumes
    ADD CONSTRAINT resumes_resume_id_key UNIQUE (resume_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_jobs_content_fts; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_jobs_content_fts ON public.jobs USING gin (to_tsvector('english'::regconfig, content));


--
-- Name: idx_jobs_created_at_desc; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_jobs_created_at_desc ON public.jobs USING btree (created_at DESC);


--
-- Name: idx_processed_jobs_keywords_gin; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_jobs_keywords_gin ON public.processed_jobs USING gin (extracted_keywords);


--
-- Name: idx_processed_jobs_processed_at_desc; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_jobs_processed_at_desc ON public.processed_jobs USING btree (processed_at DESC);


--
-- Name: idx_processed_jobs_qualifications_gin; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_jobs_qualifications_gin ON public.processed_jobs USING gin (qualifications);


--
-- Name: idx_processed_resumes_keywords_gin; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_resumes_keywords_gin ON public.processed_resumes USING gin (extracted_keywords);


--
-- Name: idx_processed_resumes_processed_at_desc; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_resumes_processed_at_desc ON public.processed_resumes USING btree (processed_at DESC);


--
-- Name: idx_processed_resumes_skills_gin; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_resumes_skills_gin ON public.processed_resumes USING gin (skills);


--
-- Name: idx_resumes_content_fts; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_resumes_content_fts ON public.resumes USING gin (to_tsvector('english'::regconfig, content));


--
-- Name: idx_resumes_created_at_desc; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_resumes_created_at_desc ON public.resumes USING btree (created_at DESC);


--
-- Name: ix_jobs_created_at; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_jobs_created_at ON public.jobs USING btree (created_at);


--
-- Name: ix_jobs_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_jobs_id ON public.jobs USING btree (id);


--
-- Name: ix_processed_jobs_job_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_processed_jobs_job_id ON public.processed_jobs USING btree (job_id);


--
-- Name: ix_processed_jobs_processed_at; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_processed_jobs_processed_at ON public.processed_jobs USING btree (processed_at);


--
-- Name: ix_processed_resumes_processed_at; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_processed_resumes_processed_at ON public.processed_resumes USING btree (processed_at);


--
-- Name: ix_processed_resumes_resume_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_processed_resumes_resume_id ON public.processed_resumes USING btree (resume_id);


--
-- Name: ix_resumes_created_at; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_resumes_created_at ON public.resumes USING btree (created_at);


--
-- Name: ix_resumes_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_resumes_id ON public.resumes USING btree (id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: job_resume job_resume_processed_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_resume
    ADD CONSTRAINT job_resume_processed_job_id_fkey FOREIGN KEY (processed_job_id) REFERENCES public.processed_jobs(job_id);


--
-- Name: job_resume job_resume_processed_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_resume
    ADD CONSTRAINT job_resume_processed_resume_id_fkey FOREIGN KEY (processed_resume_id) REFERENCES public.processed_resumes(resume_id);


--
-- Name: jobs jobs_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_resume_id_fkey FOREIGN KEY (resume_id) REFERENCES public.resumes(resume_id);


--
-- Name: processed_jobs processed_jobs_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.processed_jobs
    ADD CONSTRAINT processed_jobs_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(job_id) ON DELETE CASCADE;


--
-- Name: processed_resumes processed_resumes_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.processed_resumes
    ADD CONSTRAINT processed_resumes_resume_id_fkey FOREIGN KEY (resume_id) REFERENCES public.resumes(resume_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict WyqHcXxlpIYfWoHOBFcKUI0zJa9a2do9XpUGuYmEwHfnV0oDiwI5Wpbkw01e2TS

