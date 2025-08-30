--
-- PostgreSQL database dump
--

\restrict hjbjSvJWhh5oLJ1S891kfG0ccOuiLFJAJRhrbqzvCiZr9mXfboRkTeMPHljvq1c

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.addresses (
    id bigint NOT NULL,
    contact_id character(36) NOT NULL,
    type_id bigint,
    name character varying(255),
    street character varying(255),
    city character varying(255),
    province character varying(255),
    postal_code character varying(255),
    country character varying(255),
    latitude numeric(10,8),
    longitude numeric(11,8),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.addresses OWNER TO szjason72;

--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.addresses_id_seq OWNER TO szjason72;

--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.addresses_id_seq OWNED BY public.addresses.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    vault_id character(36) NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.companies OWNER TO szjason72;

--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.companies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.companies_id_seq OWNER TO szjason72;

--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: contact_information; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.contact_information (
    id bigint NOT NULL,
    contact_id character(36) NOT NULL,
    type_id bigint NOT NULL,
    data character varying(255) NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.contact_information OWNER TO szjason72;

--
-- Name: contact_information_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.contact_information_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contact_information_id_seq OWNER TO szjason72;

--
-- Name: contact_information_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.contact_information_id_seq OWNED BY public.contact_information.id;


--
-- Name: contact_information_types; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.contact_information_types (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    name_translation_key character varying(255),
    protocol character varying(255),
    deletable boolean DEFAULT true NOT NULL,
    type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.contact_information_types OWNER TO szjason72;

--
-- Name: contact_information_types_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.contact_information_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contact_information_types_id_seq OWNER TO szjason72;

--
-- Name: contact_information_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.contact_information_types_id_seq OWNED BY public.contact_information_types.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.contacts (
    id character(36) NOT NULL,
    vault_id character(36) NOT NULL,
    gender_id bigint,
    pronoun_id bigint,
    template_id bigint,
    company_id bigint,
    file_id bigint,
    religion_id bigint,
    first_name character varying(255),
    middle_name character varying(255),
    last_name character varying(255),
    nickname character varying(255),
    maiden_name character varying(255),
    suffix character varying(255),
    prefix character varying(255),
    job_position character varying(255),
    can_be_deleted boolean DEFAULT true NOT NULL,
    show_quick_facts boolean DEFAULT false NOT NULL,
    listed boolean DEFAULT true NOT NULL,
    vcard text,
    distant_uuid character varying(256),
    distant_etag character varying(256),
    distant_uri character varying(2096),
    last_updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.contacts OWNER TO szjason72;

--
-- Name: users; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.users (
    id character(36) NOT NULL,
    account_id character(36) NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    password character varying(255),
    two_factor_secret text,
    two_factor_recovery_codes text,
    two_factor_confirmed_at timestamp without time zone,
    email character varying(255) NOT NULL,
    email_verified_at timestamp without time zone,
    name_order character varying(255) DEFAULT '%first_name% %last_name%'::character varying NOT NULL,
    contact_sort_order character varying(255) DEFAULT 'last_updated'::character varying NOT NULL,
    date_format character varying(255) DEFAULT 'MMM DD, YYYY'::character varying NOT NULL,
    timezone character varying(255),
    number_format character varying(8) DEFAULT 'locale'::character varying NOT NULL,
    default_map_site character varying(255) DEFAULT 'open_street_maps'::character varying NOT NULL,
    distance_format character varying(255) DEFAULT 'mi'::character varying NOT NULL,
    is_account_administrator boolean DEFAULT false NOT NULL,
    is_instance_administrator boolean DEFAULT false NOT NULL,
    help_shown boolean DEFAULT true NOT NULL,
    invitation_code character varying(255),
    invitation_accepted_at timestamp without time zone,
    locale character varying(255) DEFAULT 'en'::character varying NOT NULL,
    remember_token character varying(100),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO szjason72;

--
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: contact_information id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_information ALTER COLUMN id SET DEFAULT nextval('public.contact_information_id_seq'::regclass);


--
-- Name: contact_information_types id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_information_types ALTER COLUMN id SET DEFAULT nextval('public.contact_information_types_id_seq'::regclass);


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.addresses (id, contact_id, type_id, name, street, city, province, postal_code, country, latitude, longitude, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.companies (id, vault_id, name, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contact_information; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contact_information (id, contact_id, type_id, data, created_at, updated_at) FROM stdin;
1	019802d4-082c-71a0-a201-c5dbbdaad225	1	Michael.Scott@example.com	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
2	019802d4-082c-71a0-a201-c5dbbdaad225	2	+1-555-0198	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
3	019802d4-082c-71a0-a201-c5dbbdaad225	7	linkedin.com/in/michaelscott	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
4	019802d4-0a96-717d-b9cb-395c058debe9	1	Beaulah.Lebsack@example.com	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
5	019802d4-0a96-717d-b9cb-395c058debe9	2	+1-555-0198	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
6	019802d4-0a96-717d-b9cb-395c058debe9	7	linkedin.com/in/beaulahlebsack	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
7	019802d4-0abc-71dc-941f-7398c40f3708	1	Loren.Connelly@example.com	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
8	019802d4-0abc-71dc-941f-7398c40f3708	2	+1-555-0198	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
9	019802d4-0abc-71dc-941f-7398c40f3708	7	linkedin.com/in/lorenconnelly	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
10	019802d4-0ada-733f-a74b-f3520ff07725	1	Rosalia.Will@example.com	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
11	019802d4-0ada-733f-a74b-f3520ff07725	2	+1-555-0198	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
12	019802d4-0ada-733f-a74b-f3520ff07725	7	linkedin.com/in/rosaliawill	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
13	019802d4-0afe-7242-b9b6-a2ccee66777c	1	Alivia.Wolff@example.com	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
14	019802d4-0afe-7242-b9b6-a2ccee66777c	2	+1-555-0198	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
15	019802d4-0afe-7242-b9b6-a2ccee66777c	7	linkedin.com/in/aliviawolff	2025-08-25 12:46:31.955208	2025-08-25 12:46:31.955208
\.


--
-- Data for Name: contact_information_types; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contact_information_types (id, name, name_translation_key, protocol, deletable, type, created_at, updated_at) FROM stdin;
1	Email	people.contact_information_type_email	mailto:	t	email	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
2	Phone	people.contact_information_type_phone	tel:	t	phone	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
3	Facebook	people.contact_information_type_facebook	https://facebook.com/	t	social	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
4	Twitter	people.contact_information_type_twitter	https://twitter.com/	t	social	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
5	Whatsapp	people.contact_information_type_whatsapp	https://wa.me/	t	social	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
6	Telegram	people.contact_information_type_telegram	https://t.me/	t	social	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
7	LinkedIn	people.contact_information_type_linkedin	https://linkedin.com/in/	t	social	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
8	Instagram	people.contact_information_type_instagram	https://instagram.com/	t	social	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
9	Website	people.contact_information_type_website	https://	t	website	2025-08-25 12:46:31.954227	2025-08-25 12:46:31.954227
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contacts (id, vault_id, gender_id, pronoun_id, template_id, company_id, file_id, religion_id, first_name, middle_name, last_name, nickname, maiden_name, suffix, prefix, job_position, can_be_deleted, show_quick_facts, listed, vcard, distant_uuid, distant_etag, distant_uri, last_updated_at, deleted_at, created_at, updated_at) FROM stdin;
019802d4-082c-71a0-a201-c5dbbdaad225	019802d4-0826-7098-9b33-bd283ea90225	\N	\N	\N	\N	\N	\N	Michael	\N	Scott	\N	\N	\N	\N	Regional Manager	f	f	t	\N	\N	\N	\N	\N	\N	2025-07-13 00:08:26	2025-07-13 00:08:30
019802d4-0a96-717d-b9cb-395c058debe9	019802d4-0826-7098-9b33-bd283ea90225	\N	\N	\N	\N	\N	\N	Beaulah	\N	Lebsack	\N	\N	\N	\N	Software Engineer	t	f	t	\N	\N	\N	\N	\N	\N	2025-07-13 00:08:27	2025-07-13 00:08:32
019802d4-0abc-71dc-941f-7398c40f3708	019802d4-0826-7098-9b33-bd283ea90225	\N	\N	\N	\N	\N	\N	Loren	\N	Connelly	\N	\N	\N	\N	Product Manager	t	f	t	\N	\N	\N	\N	\N	\N	2025-07-13 00:08:27	2025-07-13 00:08:33
019802d4-0ada-733f-a74b-f3520ff07725	019802d4-0826-7098-9b33-bd283ea90225	\N	\N	\N	\N	\N	\N	Rosalia	\N	Will	\N	\N	\N	\N	Data Scientist	t	f	t	\N	\N	\N	\N	\N	\N	2025-07-13 00:08:27	2025-07-13 00:08:33
019802d4-0afe-7242-b9b6-a2ccee66777c	019802d4-0826-7098-9b33-bd283ea90225	\N	\N	\N	\N	\N	\N	Alivia	\N	Wolff	\N	\N	\N	\N	UX Designer	t	f	t	\N	\N	\N	\N	\N	\N	2025-07-13 00:08:27	2025-07-13 00:08:33
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.users (id, account_id, first_name, last_name, password, two_factor_secret, two_factor_recovery_codes, two_factor_confirmed_at, email, email_verified_at, name_order, contact_sort_order, date_format, timezone, number_format, default_map_site, distance_format, is_account_administrator, is_instance_administrator, help_shown, invitation_code, invitation_accepted_at, locale, remember_token, created_at, updated_at) FROM stdin;
019802d4-02b8-715e-8943-5c1bc5fb3e87	019802d4-01d4-7000-adb4-8dbe865b6655	Michael	Scott	$2y$12$.7OCVwZtkhFGSeR3eBpW/.axCQG6oUHfglxDlX2u2o5XOLMZv7s96	\N	\N	\N	admin@admin.com	2025-07-13 00:08:26	%first_name% %last_name%	last_updated	MMM DD, YYYY	\N	locale	open_street_maps	mi	t	f	t	\N	\N	en	\N	2025-07-13 00:08:25	2025-07-13 00:08:26
019802d4-384b-7178-98d4-88e3256317b6	019802d4-375b-733d-8f80-840f5a24ccf8	John	Doe	$2y$12$wYA2yVtDH8Vg9FAptgSeJOUSAi6Lu4EotlioTsD5Lh5XrF27vtWX.	\N	\N	\N	blank@blank.com	2025-07-13 00:08:40	%first_name% %last_name%	last_updated	MMM DD, YYYY	\N	locale	open_street_maps	mi	t	f	t	\N	\N	en	\N	2025-07-13 00:08:39	2025-07-13 00:08:40
\.


--
-- Name: addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.addresses_id_seq', 1, false);


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.companies_id_seq', 1, false);


--
-- Name: contact_information_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.contact_information_id_seq', 15, true);


--
-- Name: contact_information_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.contact_information_types_id_seq', 9, true);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: contact_information contact_information_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_information
    ADD CONSTRAINT contact_information_pkey PRIMARY KEY (id);


--
-- Name: contact_information_types contact_information_types_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_information_types
    ADD CONSTRAINT contact_information_types_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--

\unrestrict hjbjSvJWhh5oLJ1S891kfG0ccOuiLFJAJRhrbqzvCiZr9mXfboRkTeMPHljvq1c

