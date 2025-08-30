--
-- PostgreSQL database dump
--

\restrict Xc0MJ3ijXcEjpasNsG9e3S6ZElt8UsrPCqJvVeg6jP9hsIQbB0qiCAJaV3ZPo4O

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
-- Name: cube; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS cube WITH SCHEMA public;


--
-- Name: EXTENSION cube; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION cube IS 'data type for multidimensional cubes';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: batch_update_privacy_controls(uuid, jsonb); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.batch_update_privacy_controls(p_user_id uuid, p_updates jsonb) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_update JSONB;
    v_count INTEGER := 0;
BEGIN
    FOR v_update IN SELECT * FROM jsonb_array_elements(p_updates)
    LOOP
        PERFORM update_user_privacy_control(
            p_user_id,
            (v_update->>'field_name')::VARCHAR(100),
            (v_update->>'label_code')::VARCHAR(20),
            (v_update->>'is_enabled')::BOOLEAN,
            (v_update->>'reason')::TEXT
        );
        v_count := v_count + 1;
    END LOOP;
    
    RETURN v_count;
END;
$$;


ALTER FUNCTION public.batch_update_privacy_controls(p_user_id uuid, p_updates jsonb) OWNER TO szjason72;

--
-- Name: calculate_distance(numeric, numeric, numeric, numeric); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.calculate_distance(lat1 numeric, lon1 numeric, lat2 numeric, lon2 numeric) RETURNS real
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN 6371 * acos(
        cos(radians(lat1)) * cos(radians(lat2)) * 
        cos(radians(lon2) - radians(lon1)) + 
        sin(radians(lat1)) * sin(radians(lat2))
    );
END;
$$;


ALTER FUNCTION public.calculate_distance(lat1 numeric, lon1 numeric, lat2 numeric, lon2 numeric) OWNER TO szjason72;

--
-- Name: calculate_job_match_score(real[], real[]); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.calculate_job_match_score(resume_embedding real[], job_embedding real[]) RETURNS real
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN cosine_similarity(resume_embedding, job_embedding);
END;
$$;


ALTER FUNCTION public.calculate_job_match_score(resume_embedding real[], job_embedding real[]) OWNER TO szjason72;

--
-- Name: cosine_similarity(real[], real[]); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.cosine_similarity(a real[], b real[]) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
    dot_product REAL := 0;
    norm_a REAL := 0;
    norm_b REAL := 0;
    i INTEGER;
BEGIN
    -- 计算点积和向量范数
    FOR i IN 1..array_length(a, 1) LOOP
        dot_product := dot_product + a[i] * b[i];
        norm_a := norm_a + a[i] * a[i];
        norm_b := norm_b + b[i] * b[i];
    END LOOP;
    
    -- 计算余弦相似度
    IF norm_a = 0 OR norm_b = 0 THEN
        RETURN 0;
    ELSE
        RETURN dot_product / (sqrt(norm_a) * sqrt(norm_b));
    END IF;
END;
$$;


ALTER FUNCTION public.cosine_similarity(a real[], b real[]) OWNER TO szjason72;

--
-- Name: find_nearby_companies(numeric, numeric, real); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.find_nearby_companies(target_lat numeric, target_lon numeric, radius_km real DEFAULT 50) RETURNS TABLE(company_id bigint, company_name character varying, distance_km real, industry character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.name,
        calculate_distance(target_lat, target_lon, c.latitude, c.longitude) as distance_km,
        c.industry
    FROM companies c
    WHERE c.latitude IS NOT NULL 
    AND c.longitude IS NOT NULL
    AND calculate_distance(target_lat, target_lon, c.latitude, c.longitude) <= radius_km
    ORDER BY distance_km;
END;
$$;


ALTER FUNCTION public.find_nearby_companies(target_lat numeric, target_lon numeric, radius_km real) OWNER TO szjason72;

--
-- Name: get_masked_personal_data(uuid, character varying, character varying); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.get_masked_personal_data(p_user_id uuid, p_table_name character varying, p_column_name character varying) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $_$
DECLARE
    v_sensitivity_level VARCHAR(10);
    v_masking_type VARCHAR(20);
    v_masking_pattern VARCHAR(100);
    v_replacement_char VARCHAR(10);
    v_start_position INTEGER;
    v_end_position INTEGER;
    v_original_value TEXT;
    v_masked_value TEXT;
BEGIN
    -- 获取敏感性级别
    SELECT psl.level_code INTO v_sensitivity_level
    FROM personal_data_fields pdf
    JOIN privacy_sensitivity_levels psl ON pdf.sensitivity_level_id = psl.id
    WHERE pdf.table_name = p_table_name AND pdf.column_name = p_column_name;
    
    -- 检查用户权限
    IF v_sensitivity_level = 'P0' THEN
        -- 公开信息，直接返回
        EXECUTE format('SELECT %I FROM %I WHERE user_id = $1', p_column_name, p_table_name)
        INTO v_original_value
        USING p_user_id;
        RETURN v_original_value;
    END IF;
    
    -- 检查用户是否同意
    IF NOT EXISTS (
        SELECT 1 FROM user_privacy_preferences upp
        JOIN personal_data_fields pdf ON upp.field_id = pdf.id
        WHERE upp.user_id = p_user_id 
        AND pdf.table_name = p_table_name 
        AND pdf.column_name = p_column_name
        AND upp.consent_given = TRUE
    ) THEN
        RETURN '***未授权访问***';
    END IF;
    
    -- 获取原始值
    EXECUTE format('SELECT %I FROM %I WHERE user_id = $1', p_column_name, p_table_name)
    INTO v_original_value
    USING p_user_id;
    
    -- 获取脱敏规则
    SELECT dmr.masking_type, dmr.masking_pattern, dmr.replacement_char, 
           dmr.start_position, dmr.end_position
    INTO v_masking_type, v_masking_pattern, v_replacement_char, 
         v_start_position, v_end_position
    FROM data_masking_rules dmr
    JOIN personal_data_fields pdf ON dmr.field_id = pdf.id
    WHERE pdf.table_name = p_table_name AND pdf.column_name = p_column_name;
    
    -- 应用脱敏规则
    IF v_masking_type = 'partial' THEN
        IF v_original_value IS NOT NULL THEN
            v_masked_value := substring(v_original_value from 1 for v_start_position - 1) ||
                             repeat(v_replacement_char, length(v_original_value) - v_start_position + 1);
        END IF;
    ELSIF v_masking_type = 'full' THEN
        v_masked_value := repeat(v_replacement_char, length(v_original_value));
    ELSE
        v_masked_value := v_original_value;
    END IF;
    
    RETURN v_masked_value;
END;
$_$;


ALTER FUNCTION public.get_masked_personal_data(p_user_id uuid, p_table_name character varying, p_column_name character varying) OWNER TO szjason72;

--
-- Name: get_user_privacy_controls(uuid); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.get_user_privacy_controls(p_user_id uuid) RETURNS TABLE(field_name character varying, field_category character varying, sensitivity_level character varying, label_code character varying, label_name character varying, label_type character varying, is_enabled boolean, color_code character varying, icon_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pdf.field_name,
        pdf.data_category,
        psl.level_code,
        pcl.label_code,
        pcl.label_name,
        pcl.label_type,
        upc.is_enabled,
        pcl.color_code,
        pcl.icon_name
    FROM personal_data_fields pdf
    JOIN privacy_sensitivity_levels psl ON pdf.sensitivity_level_id = psl.id
    JOIN field_privacy_controls fpc ON pdf.id = fpc.field_id
    JOIN privacy_control_labels pcl ON fpc.label_id = pcl.id
    LEFT JOIN user_privacy_controls upc ON upc.user_id = p_user_id 
        AND upc.field_id = pdf.id 
        AND upc.label_id = pcl.id
    WHERE upc.user_id = p_user_id OR upc.user_id IS NULL
    ORDER BY pdf.field_name, pcl.label_type, pcl.label_code;
END;
$$;


ALTER FUNCTION public.get_user_privacy_controls(p_user_id uuid) OWNER TO szjason72;

--
-- Name: log_data_access(); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.log_data_access() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO data_access_logs (
        user_id, accessed_user_id, table_name, column_name, 
        access_type, access_reason, ip_address, user_agent, is_authorized
    ) VALUES (
        current_setting('app.current_user_id')::UUID,
        NEW.user_id,
        TG_TABLE_NAME,
        TG_ARGV[0],
        TG_OP,
        current_setting('app.access_reason', TRUE),
        inet_client_addr(),
        current_setting('app.user_agent', TRUE),
        TRUE
    );
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_data_access() OWNER TO szjason72;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO szjason72;

--
-- Name: update_user_privacy_control(uuid, character varying, character varying, boolean, text); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.update_user_privacy_control(p_user_id uuid, p_field_name character varying, p_label_code character varying, p_is_enabled boolean, p_reason text DEFAULT NULL::text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_field_id BIGINT;
    v_label_id BIGINT;
    v_control_id BIGINT;
BEGIN
    -- 获取字段ID
    SELECT id INTO v_field_id
    FROM personal_data_fields
    WHERE field_name = p_field_name;
    
    IF v_field_id IS NULL THEN
        RAISE EXCEPTION 'Field not found: %', p_field_name;
    END IF;
    
    -- 获取标签ID
    SELECT id INTO v_label_id
    FROM privacy_control_labels
    WHERE label_code = p_label_code;
    
    IF v_label_id IS NULL THEN
        RAISE EXCEPTION 'Label not found: %', p_label_code;
    END IF;
    
    -- 更新或插入用户隐私控制设置
    INSERT INTO user_privacy_controls (user_id, field_id, label_id, is_enabled, enabled_date, disabled_date, reason)
    VALUES (p_user_id, v_field_id, v_label_id, p_is_enabled, 
            CASE WHEN p_is_enabled THEN CURRENT_TIMESTAMP ELSE NULL END,
            CASE WHEN NOT p_is_enabled THEN CURRENT_TIMESTAMP ELSE NULL END,
            p_reason)
    ON CONFLICT (user_id, field_id, label_id) 
    DO UPDATE SET 
        is_enabled = EXCLUDED.is_enabled,
        enabled_date = EXCLUDED.enabled_date,
        disabled_date = EXCLUDED.disabled_date,
        reason = EXCLUDED.reason,
        updated_at = CURRENT_TIMESTAMP;
    
    -- 记录访问日志
    INSERT INTO data_access_logs (user_id, table_name, column_name, access_type, access_reason)
    VALUES (p_user_id, 'user_privacy_controls', p_field_name, 'update', 
            'Privacy control updated: ' || p_label_code || ' = ' || p_is_enabled);
    
    RETURN TRUE;
END;
$$;


ALTER FUNCTION public.update_user_privacy_control(p_user_id uuid, p_field_name character varying, p_label_code character varying, p_is_enabled boolean, p_reason text) OWNER TO szjason72;

--
-- Name: validate_privacy_controls(uuid); Type: FUNCTION; Schema: public; Owner: szjason72
--

CREATE FUNCTION public.validate_privacy_controls(p_user_id uuid) RETURNS TABLE(field_name character varying, issue_type character varying, issue_description text, recommendation text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pdf.field_name,
        'consent_missing' as issue_type,
        '用户未同意收集此敏感信息' as issue_description,
        '请用户明确同意收集此信息' as recommendation
    FROM personal_data_fields pdf
    JOIN privacy_sensitivity_levels psl ON pdf.sensitivity_level_id = psl.id
    LEFT JOIN user_privacy_preferences upp ON upp.user_id = p_user_id AND upp.field_id = pdf.id
    WHERE psl.level_code IN ('P2', 'P3')
    AND (upp.consent_given IS NULL OR upp.consent_given = FALSE)
    
    UNION ALL
    
    SELECT 
        pdf.field_name,
        'control_disabled' as issue_type,
        '必要的隐私控制被禁用' as issue_description,
        '建议启用此隐私控制' as recommendation
    FROM personal_data_fields pdf
    JOIN field_privacy_controls fpc ON pdf.id = fpc.field_id
    JOIN privacy_control_labels pcl ON fpc.label_id = pcl.id
    LEFT JOIN user_privacy_controls upc ON upc.user_id = p_user_id 
        AND upc.field_id = pdf.id 
        AND upc.label_id = pcl.id
    WHERE fpc.control_type = 'required'
    AND (upc.is_enabled IS NULL OR upc.is_enabled = FALSE);
END;
$$;


ALTER FUNCTION public.validate_privacy_controls(p_user_id uuid) OWNER TO szjason72;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activities; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.activities (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    contact_id uuid,
    activity_type_id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    activity_date timestamp without time zone NOT NULL,
    duration_minutes integer,
    location character varying(255),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.activities OWNER TO szjason72;

--
-- Name: activities_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.activities_id_seq OWNER TO szjason72;

--
-- Name: activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.activities_id_seq OWNED BY public.activities.id;


--
-- Name: activity_types; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.activity_types (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(100),
    icon character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.activity_types OWNER TO szjason72;

--
-- Name: activity_types_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.activity_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.activity_types_id_seq OWNER TO szjason72;

--
-- Name: activity_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.activity_types_id_seq OWNED BY public.activity_types.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.addresses (
    id bigint NOT NULL,
    contact_id uuid NOT NULL,
    type character varying(50) DEFAULT 'home'::character varying,
    street character varying(255),
    city character varying(255),
    state character varying(255),
    postal_code character varying(50),
    country character varying(255),
    is_primary boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
-- Name: ai_embeddings; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.ai_embeddings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    entity_type character varying(50) NOT NULL,
    entity_id uuid NOT NULL,
    embedding_model character varying(100) NOT NULL,
    embedding_version character varying(20) NOT NULL,
    embedding_vector real[],
    content_hash character varying(64),
    content_preview text,
    metadata jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ai_embeddings OWNER TO szjason72;

--
-- Name: career_tracking; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.career_tracking (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    applications_submitted integer DEFAULT 0,
    interviews_scheduled integer DEFAULT 0,
    interviews_completed integer DEFAULT 0,
    offers_received integer DEFAULT 0,
    skills_developed jsonb,
    certifications_earned jsonb,
    networking_events_attended integer DEFAULT 0,
    tracking_date date NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.career_tracking OWNER TO szjason72;

--
-- Name: career_tracking_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.career_tracking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.career_tracking_id_seq OWNER TO szjason72;

--
-- Name: career_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.career_tracking_id_seq OWNED BY public.career_tracking.id;


--
-- Name: career_trajectory; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.career_trajectory (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    trajectory_type character varying(50) NOT NULL,
    from_location character varying(255),
    to_location character varying(255),
    from_industry character varying(100),
    to_industry character varying(100),
    from_role_level character varying(50),
    to_role_level character varying(50),
    transition_date date,
    transition_reason text,
    distance_km real,
    salary_change_percentage real,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.career_trajectory OWNER TO szjason72;

--
-- Name: casbin_rule; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.casbin_rule (
    id bigint NOT NULL,
    ptype character varying(100),
    v0 character varying(100),
    v1 character varying(100),
    v2 character varying(100),
    v3 character varying(100),
    v4 character varying(100),
    v5 character varying(100)
);


ALTER TABLE public.casbin_rule OWNER TO szjason72;

--
-- Name: casbin_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.casbin_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.casbin_rule_id_seq OWNER TO szjason72;

--
-- Name: casbin_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.casbin_rule_id_seq OWNED BY public.casbin_rule.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.companies (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255),
    website character varying(255),
    industry character varying(255),
    size character varying(100),
    founded_year integer,
    description text,
    logo_url character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    address_line1 character varying(255),
    address_line2 character varying(255),
    city character varying(100),
    state character varying(100),
    postal_code character varying(20),
    country character varying(100),
    latitude numeric(10,8),
    longitude numeric(11,8),
    timezone character varying(50),
    region character varying(100)
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
    contact_id uuid NOT NULL,
    type_id bigint NOT NULL,
    data character varying(255) NOT NULL,
    is_primary boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
    type character varying(50) NOT NULL,
    icon character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
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
-- Name: contact_recommendations; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.contact_recommendations (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    job_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    recommendation_score real NOT NULL,
    relationship_strength real,
    contact_relevance_score real,
    recommendation_reason text,
    is_contacted boolean DEFAULT false,
    contact_date timestamp without time zone,
    contact_notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.contact_recommendations OWNER TO szjason72;

--
-- Name: contact_references; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.contact_references (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    relationship_type character varying(100),
    can_reference boolean DEFAULT true,
    preferred_contact_method character varying(50),
    notes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.contact_references OWNER TO szjason72;

--
-- Name: contact_references_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.contact_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contact_references_id_seq OWNER TO szjason72;

--
-- Name: contact_references_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.contact_references_id_seq OWNED BY public.contact_references.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.contacts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    first_name character varying(255),
    middle_name character varying(255),
    last_name character varying(255),
    nickname character varying(255),
    maiden_name character varying(255),
    suffix character varying(255),
    prefix character varying(255),
    job_position character varying(255),
    company_id bigint,
    avatar_url character varying(500),
    notes text,
    is_favorite boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.contacts OWNER TO szjason72;

--
-- Name: data_access_logs; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.data_access_logs (
    id bigint NOT NULL,
    user_id uuid,
    accessed_user_id uuid,
    table_name character varying(100) NOT NULL,
    column_name character varying(100) NOT NULL,
    access_type character varying(20) NOT NULL,
    access_reason text,
    ip_address inet,
    user_agent text,
    access_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_authorized boolean DEFAULT true
);


ALTER TABLE public.data_access_logs OWNER TO szjason72;

--
-- Name: data_access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.data_access_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.data_access_logs_id_seq OWNER TO szjason72;

--
-- Name: data_access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.data_access_logs_id_seq OWNED BY public.data_access_logs.id;


--
-- Name: data_masking_rules; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.data_masking_rules (
    id bigint NOT NULL,
    field_id bigint NOT NULL,
    masking_type character varying(20) NOT NULL,
    masking_pattern character varying(100),
    replacement_char character varying(10) DEFAULT '*'::character varying,
    start_position integer DEFAULT 1,
    end_position integer,
    custom_function text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.data_masking_rules OWNER TO szjason72;

--
-- Name: data_masking_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.data_masking_rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.data_masking_rules_id_seq OWNER TO szjason72;

--
-- Name: data_masking_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.data_masking_rules_id_seq OWNED BY public.data_masking_rules.id;


--
-- Name: database_metadata; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.database_metadata (
    id integer NOT NULL,
    version character varying(20) NOT NULL,
    name character varying(100) DEFAULT 'Zervi'::character varying NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.database_metadata OWNER TO szjason72;

--
-- Name: database_metadata_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.database_metadata_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.database_metadata_id_seq OWNER TO szjason72;

--
-- Name: database_metadata_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.database_metadata_id_seq OWNED BY public.database_metadata.id;


--
-- Name: education; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.education (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    institution_name character varying(255) NOT NULL,
    degree character varying(255),
    field_of_study character varying(255),
    start_date date,
    end_date date,
    gpa numeric(3,2),
    description text,
    achievements jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    institution_address_line1 character varying(255),
    institution_address_line2 character varying(255),
    institution_city character varying(100),
    institution_state character varying(100),
    institution_postal_code character varying(20),
    institution_country character varying(100),
    institution_latitude numeric(10,8),
    institution_longitude numeric(11,8)
);


ALTER TABLE public.education OWNER TO szjason72;

--
-- Name: education_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.education_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.education_id_seq OWNER TO szjason72;

--
-- Name: education_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.education_id_seq OWNED BY public.education.id;


--
-- Name: field_privacy_controls; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.field_privacy_controls (
    id bigint NOT NULL,
    field_id bigint NOT NULL,
    label_id bigint NOT NULL,
    control_type character varying(20) NOT NULL,
    default_value boolean DEFAULT false,
    validation_rules jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.field_privacy_controls OWNER TO szjason72;

--
-- Name: field_privacy_controls_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.field_privacy_controls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.field_privacy_controls_id_seq OWNER TO szjason72;

--
-- Name: field_privacy_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.field_privacy_controls_id_seq OWNED BY public.field_privacy_controls.id;


--
-- Name: files; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.files (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    filename character varying(255) NOT NULL,
    original_filename character varying(255) NOT NULL,
    file_path character varying(500) NOT NULL,
    file_size bigint,
    mime_type character varying(100),
    category character varying(100),
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.files OWNER TO szjason72;

--
-- Name: files_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.files_id_seq OWNER TO szjason72;

--
-- Name: files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.files_id_seq OWNED BY public.files.id;


--
-- Name: job_applications; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.job_applications (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    job_id uuid NOT NULL,
    resume_id uuid NOT NULL,
    application_date date NOT NULL,
    status character varying(20) DEFAULT 'applied'::character varying,
    notes text,
    follow_up_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT job_applications_status_check CHECK (((status)::text = ANY ((ARRAY['applied'::character varying, 'under_review'::character varying, 'interview_scheduled'::character varying, 'interviewed'::character varying, 'offer_received'::character varying, 'rejected'::character varying, 'withdrawn'::character varying])::text[])))
);


ALTER TABLE public.job_applications OWNER TO szjason72;

--
-- Name: job_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.job_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.job_applications_id_seq OWNER TO szjason72;

--
-- Name: job_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.job_applications_id_seq OWNED BY public.job_applications.id;


--
-- Name: job_embeddings; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.job_embeddings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    job_id uuid NOT NULL,
    embedding_type character varying(50) NOT NULL,
    embedding_model character varying(100) NOT NULL,
    embedding_vector real[],
    content_hash character varying(64),
    similarity_threshold real DEFAULT 0.8,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.job_embeddings OWNER TO szjason72;

--
-- Name: job_matches; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.job_matches (
    job_id uuid NOT NULL,
    resume_id uuid NOT NULL,
    overall_score numeric(5,2),
    skills_match_score numeric(5,2),
    experience_match_score numeric(5,2),
    education_match_score numeric(5,2),
    matched_keywords jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.job_matches OWNER TO szjason72;

--
-- Name: jobs; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.jobs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    company_name character varying(255) NOT NULL,
    company_id bigint,
    content text NOT NULL,
    location character varying(255),
    employment_type character varying(100),
    salary_range character varying(100),
    remote_option character varying(50),
    application_deadline date,
    source character varying(100),
    source_url character varying(500),
    status character varying(20) DEFAULT 'saved'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    company_address_line1 character varying(255),
    company_address_line2 character varying(255),
    company_city character varying(100),
    company_state character varying(100),
    company_postal_code character varying(20),
    company_country character varying(100),
    company_latitude numeric(10,8),
    company_longitude numeric(11,8),
    work_location_type character varying(50) DEFAULT 'office'::character varying,
    relocation_required boolean DEFAULT false,
    CONSTRAINT jobs_status_check CHECK (((status)::text = ANY ((ARRAY['saved'::character varying, 'applied'::character varying, 'interviewing'::character varying, 'offered'::character varying, 'rejected'::character varying, 'withdrawn'::character varying])::text[])))
);


ALTER TABLE public.jobs OWNER TO szjason72;

--
-- Name: location_analytics; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.location_analytics (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    location_type character varying(50) NOT NULL,
    city character varying(100),
    state character varying(100),
    country character varying(100),
    latitude numeric(10,8),
    longitude numeric(11,8),
    start_date date,
    end_date date,
    duration_months integer,
    is_current boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.location_analytics OWNER TO szjason72;

--
-- Name: resumes; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.resumes (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    content_type character varying(50) DEFAULT 'text'::character varying,
    version character varying(20) DEFAULT '1.0'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.resumes OWNER TO szjason72;

--
-- Name: work_experiences; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.work_experiences (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    company_name character varying(255) NOT NULL,
    company_id bigint,
    job_title character varying(255) NOT NULL,
    start_date date,
    end_date date,
    is_current boolean DEFAULT false,
    description text,
    achievements jsonb,
    skills_used jsonb,
    location character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    company_address_line1 character varying(255),
    company_address_line2 character varying(255),
    company_city character varying(100),
    company_state character varying(100),
    company_postal_code character varying(20),
    company_country character varying(100),
    company_latitude numeric(10,8),
    company_longitude numeric(11,8),
    work_location_type character varying(50) DEFAULT 'office'::character varying,
    relocation_required boolean DEFAULT false
);


ALTER TABLE public.work_experiences OWNER TO szjason72;

--
-- Name: location_based_matches; Type: VIEW; Schema: public; Owner: szjason72
--

CREATE VIEW public.location_based_matches AS
 SELECT r.id AS resume_id,
    j.id AS job_id,
    r.title AS resume_title,
    j.title AS job_title,
    j.company_name,
    j.company_city,
    j.company_state,
    j.company_country,
    public.calculate_distance(we.company_latitude, we.company_longitude, j.company_latitude, j.company_longitude) AS distance_km,
        CASE
            WHEN (public.calculate_distance(we.company_latitude, we.company_longitude, j.company_latitude, j.company_longitude) <= (50)::double precision) THEN 'Local'::text
            WHEN (public.calculate_distance(we.company_latitude, we.company_longitude, j.company_latitude, j.company_longitude) <= (200)::double precision) THEN 'Regional'::text
            ELSE 'Remote/Relocation'::text
        END AS location_match_type
   FROM ((public.resumes r
     JOIN public.work_experiences we ON ((r.user_id = we.user_id)))
     CROSS JOIN public.jobs j)
  WHERE ((we.is_current = true) AND (j.company_latitude IS NOT NULL) AND (j.company_longitude IS NOT NULL) AND (we.company_latitude IS NOT NULL) AND (we.company_longitude IS NOT NULL));


ALTER TABLE public.location_based_matches OWNER TO szjason72;

--
-- Name: network_analytics; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.network_analytics (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    total_contacts integer DEFAULT 0,
    professional_contacts integer DEFAULT 0,
    personal_contacts integer DEFAULT 0,
    strong_relationships integer DEFAULT 0,
    weak_relationships integer DEFAULT 0,
    last_activity_date date,
    networking_score numeric(5,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.network_analytics OWNER TO szjason72;

--
-- Name: network_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.network_analytics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.network_analytics_id_seq OWNER TO szjason72;

--
-- Name: network_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.network_analytics_id_seq OWNED BY public.network_analytics.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.notes (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    contact_id uuid,
    job_id uuid,
    title character varying(255),
    content text NOT NULL,
    category character varying(100),
    is_private boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notes OWNER TO szjason72;

--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notes_id_seq OWNER TO szjason72;

--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: personal_data_fields; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.personal_data_fields (
    id bigint NOT NULL,
    table_name character varying(100) NOT NULL,
    column_name character varying(100) NOT NULL,
    field_name character varying(100) NOT NULL,
    sensitivity_level_id bigint NOT NULL,
    data_category character varying(50) NOT NULL,
    description text,
    is_required boolean DEFAULT false,
    is_encrypted boolean DEFAULT false,
    is_masked boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.personal_data_fields OWNER TO szjason72;

--
-- Name: personal_data_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.personal_data_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.personal_data_fields_id_seq OWNER TO szjason72;

--
-- Name: personal_data_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.personal_data_fields_id_seq OWNED BY public.personal_data_fields.id;


--
-- Name: privacy_control_labels; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.privacy_control_labels (
    id bigint NOT NULL,
    label_code character varying(20) NOT NULL,
    label_name character varying(100) NOT NULL,
    label_type character varying(20) NOT NULL,
    description text,
    color_code character varying(7) DEFAULT '#007bff'::character varying,
    icon_name character varying(50),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.privacy_control_labels OWNER TO szjason72;

--
-- Name: privacy_control_labels_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.privacy_control_labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.privacy_control_labels_id_seq OWNER TO szjason72;

--
-- Name: privacy_control_labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.privacy_control_labels_id_seq OWNED BY public.privacy_control_labels.id;


--
-- Name: privacy_sensitivity_levels; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.privacy_sensitivity_levels (
    id bigint NOT NULL,
    level_code character varying(10) NOT NULL,
    level_name character varying(50) NOT NULL,
    description text,
    legal_basis text,
    retention_period_months integer,
    consent_required boolean DEFAULT true,
    encryption_required boolean DEFAULT false,
    access_logging_required boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.privacy_sensitivity_levels OWNER TO szjason72;

--
-- Name: privacy_sensitivity_levels_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.privacy_sensitivity_levels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.privacy_sensitivity_levels_id_seq OWNER TO szjason72;

--
-- Name: privacy_sensitivity_levels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.privacy_sensitivity_levels_id_seq OWNED BY public.privacy_sensitivity_levels.id;


--
-- Name: processed_jobs; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.processed_jobs (
    job_id uuid NOT NULL,
    job_title character varying(255) NOT NULL,
    company_profile text,
    location character varying(255),
    date_posted character varying(100),
    employment_type character varying(100),
    job_summary text NOT NULL,
    key_responsibilities jsonb,
    qualifications jsonb,
    compensation_and_benefits jsonb,
    application_info jsonb,
    extracted_keywords jsonb,
    processed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.processed_jobs OWNER TO szjason72;

--
-- Name: processed_resumes; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.processed_resumes (
    resume_id uuid NOT NULL,
    personal_data jsonb,
    experiences jsonb,
    projects jsonb,
    skills jsonb,
    research_work jsonb,
    achievements jsonb,
    education jsonb,
    certifications jsonb,
    languages jsonb,
    extracted_keywords jsonb,
    processed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.processed_resumes OWNER TO szjason72;

--
-- Name: projects; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.projects (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    technologies jsonb,
    start_date date,
    end_date date,
    url character varying(500),
    github_url character varying(500),
    is_featured boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.projects OWNER TO szjason72;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO szjason72;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: relationship_types; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.relationship_types (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.relationship_types OWNER TO szjason72;

--
-- Name: relationship_types_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.relationship_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relationship_types_id_seq OWNER TO szjason72;

--
-- Name: relationship_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.relationship_types_id_seq OWNED BY public.relationship_types.id;


--
-- Name: relationships; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.relationships (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    contact_id uuid NOT NULL,
    relationship_type_id bigint,
    notes text,
    strength_level character varying(20) DEFAULT 'moderate'::character varying,
    last_contact_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT relationships_strength_level_check CHECK (((strength_level)::text = ANY ((ARRAY['weak'::character varying, 'moderate'::character varying, 'strong'::character varying])::text[])))
);


ALTER TABLE public.relationships OWNER TO szjason72;

--
-- Name: relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relationships_id_seq OWNER TO szjason72;

--
-- Name: relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.relationships_id_seq OWNED BY public.relationships.id;


--
-- Name: reminders; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.reminders (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    contact_id uuid,
    title character varying(255) NOT NULL,
    description text,
    reminder_date timestamp without time zone NOT NULL,
    is_recurring boolean DEFAULT false,
    recurrence_pattern character varying(100),
    is_completed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.reminders OWNER TO szjason72;

--
-- Name: reminders_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.reminders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reminders_id_seq OWNER TO szjason72;

--
-- Name: reminders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.reminders_id_seq OWNED BY public.reminders.id;


--
-- Name: resume_embeddings; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.resume_embeddings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    resume_id uuid NOT NULL,
    embedding_type character varying(50) NOT NULL,
    embedding_model character varying(100) NOT NULL,
    embedding_vector real[],
    content_hash character varying(64),
    similarity_threshold real DEFAULT 0.8,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.resume_embeddings OWNER TO szjason72;

--
-- Name: resume_job_matches; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.resume_job_matches (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    resume_id uuid NOT NULL,
    job_id uuid NOT NULL,
    overall_score real NOT NULL,
    skill_match_score real,
    experience_match_score real,
    education_match_score real,
    location_match_score real,
    salary_match_score real,
    culture_match_score real,
    match_details jsonb,
    is_recommended boolean DEFAULT false,
    recommendation_reason text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.resume_job_matches OWNER TO szjason72;

--
-- Name: skill_embeddings; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.skill_embeddings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    skill_id bigint NOT NULL,
    embedding_model character varying(100) NOT NULL,
    embedding_vector real[],
    content_hash character varying(64),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.skill_embeddings OWNER TO szjason72;

--
-- Name: skills; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.skills (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    category character varying(100),
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.skills OWNER TO szjason72;

--
-- Name: skills_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.skills_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.skills_id_seq OWNER TO szjason72;

--
-- Name: skills_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.skills_id_seq OWNED BY public.skills.id;


--
-- Name: tasks; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.tasks (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    contact_id uuid,
    title character varying(255) NOT NULL,
    description text,
    due_date date,
    priority character varying(20) DEFAULT 'medium'::character varying,
    status character varying(20) DEFAULT 'pending'::character varying,
    category character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tasks_priority_check CHECK (((priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying])::text[]))),
    CONSTRAINT tasks_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.tasks OWNER TO szjason72;

--
-- Name: tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tasks_id_seq OWNER TO szjason72;

--
-- Name: tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.tasks_id_seq OWNED BY public.tasks.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email text,
    first_name character varying(255),
    last_name character varying(255),
    password character varying(255),
    two_factor_secret text,
    two_factor_recovery_codes text,
    two_factor_confirmed_at timestamp without time zone,
    email_verified_at timestamp without time zone,
    name_order character varying(255) DEFAULT '%first_name% %last_name%'::character varying,
    date_format character varying(255) DEFAULT 'MMM DD, YYYY'::character varying,
    timezone character varying(255) DEFAULT 'UTC'::character varying,
    locale character varying(255) DEFAULT 'en'::character varying,
    is_administrator boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    deleted_at timestamp with time zone,
    password_hash character varying(255),
    phone character varying(255),
    is_active boolean DEFAULT true,
    date_of_birth timestamp without time zone,
    gender character varying(255),
    profile_picture character varying(255),
    last_login_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO szjason72;

--
-- Name: user_career_trajectory; Type: VIEW; Schema: public; Owner: szjason72
--

CREATE VIEW public.user_career_trajectory AS
 SELECT u.id AS user_id,
    concat(u.first_name, ' ', u.last_name) AS user_name,
    we.company_name,
    we.job_title,
    we.start_date,
    we.end_date,
    we.company_city,
    we.company_state,
    we.company_country,
    we.company_latitude,
    we.company_longitude,
    c.name AS company_name_full,
    c.industry,
    c.size AS company_size
   FROM ((public.users u
     JOIN public.work_experiences we ON ((u.id = we.user_id)))
     LEFT JOIN public.companies c ON ((we.company_id = c.id)))
  ORDER BY u.id, we.start_date DESC;


ALTER TABLE public.user_career_trajectory OWNER TO szjason72;

--
-- Name: user_privacy_controls; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.user_privacy_controls (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    field_id bigint NOT NULL,
    label_id bigint NOT NULL,
    is_enabled boolean DEFAULT false,
    enabled_date timestamp without time zone,
    disabled_date timestamp without time zone,
    reason text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_privacy_controls OWNER TO szjason72;

--
-- Name: user_privacy_controls_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.user_privacy_controls_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_privacy_controls_id_seq OWNER TO szjason72;

--
-- Name: user_privacy_controls_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.user_privacy_controls_id_seq OWNED BY public.user_privacy_controls.id;


--
-- Name: user_privacy_preferences; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.user_privacy_preferences (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    field_id bigint NOT NULL,
    is_enabled boolean DEFAULT true,
    consent_given boolean DEFAULT false,
    consent_date timestamp without time zone,
    consent_version character varying(20),
    data_usage_purposes jsonb,
    retention_consent boolean DEFAULT false,
    sharing_consent boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_privacy_preferences OWNER TO szjason72;

--
-- Name: user_privacy_preferences_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.user_privacy_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_privacy_preferences_id_seq OWNER TO szjason72;

--
-- Name: user_privacy_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.user_privacy_preferences_id_seq OWNED BY public.user_privacy_preferences.id;


--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.user_profiles (
    user_id uuid NOT NULL,
    avatar_url character varying(500),
    bio text,
    location character varying(255),
    website character varying(255),
    linkedin_url character varying(255),
    github_url character varying(255),
    twitter_url character varying(255),
    phone character varying(50),
    date_of_birth date,
    gender_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_profiles OWNER TO szjason72;

--
-- Name: user_skills; Type: TABLE; Schema: public; Owner: szjason72
--

CREATE TABLE public.user_skills (
    user_id uuid NOT NULL,
    skill_id bigint NOT NULL,
    proficiency_level character varying(20) DEFAULT 'intermediate'::character varying,
    years_of_experience integer,
    is_primary boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_skills_proficiency_level_check CHECK (((proficiency_level)::text = ANY ((ARRAY['beginner'::character varying, 'intermediate'::character varying, 'advanced'::character varying, 'expert'::character varying])::text[])))
);


ALTER TABLE public.user_skills OWNER TO szjason72;

--
-- Name: work_experiences_id_seq; Type: SEQUENCE; Schema: public; Owner: szjason72
--

CREATE SEQUENCE public.work_experiences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.work_experiences_id_seq OWNER TO szjason72;

--
-- Name: work_experiences_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: szjason72
--

ALTER SEQUENCE public.work_experiences_id_seq OWNED BY public.work_experiences.id;


--
-- Name: activities id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.activities ALTER COLUMN id SET DEFAULT nextval('public.activities_id_seq'::regclass);


--
-- Name: activity_types id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.activity_types ALTER COLUMN id SET DEFAULT nextval('public.activity_types_id_seq'::regclass);


--
-- Name: addresses id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.addresses ALTER COLUMN id SET DEFAULT nextval('public.addresses_id_seq'::regclass);


--
-- Name: career_tracking id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.career_tracking ALTER COLUMN id SET DEFAULT nextval('public.career_tracking_id_seq'::regclass);


--
-- Name: casbin_rule id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.casbin_rule ALTER COLUMN id SET DEFAULT nextval('public.casbin_rule_id_seq'::regclass);


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
-- Name: contact_references id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_references ALTER COLUMN id SET DEFAULT nextval('public.contact_references_id_seq'::regclass);


--
-- Name: data_access_logs id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.data_access_logs ALTER COLUMN id SET DEFAULT nextval('public.data_access_logs_id_seq'::regclass);


--
-- Name: data_masking_rules id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.data_masking_rules ALTER COLUMN id SET DEFAULT nextval('public.data_masking_rules_id_seq'::regclass);


--
-- Name: database_metadata id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.database_metadata ALTER COLUMN id SET DEFAULT nextval('public.database_metadata_id_seq'::regclass);


--
-- Name: education id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.education ALTER COLUMN id SET DEFAULT nextval('public.education_id_seq'::regclass);


--
-- Name: field_privacy_controls id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.field_privacy_controls ALTER COLUMN id SET DEFAULT nextval('public.field_privacy_controls_id_seq'::regclass);


--
-- Name: files id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.files ALTER COLUMN id SET DEFAULT nextval('public.files_id_seq'::regclass);


--
-- Name: job_applications id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_applications ALTER COLUMN id SET DEFAULT nextval('public.job_applications_id_seq'::regclass);


--
-- Name: network_analytics id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.network_analytics ALTER COLUMN id SET DEFAULT nextval('public.network_analytics_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: personal_data_fields id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.personal_data_fields ALTER COLUMN id SET DEFAULT nextval('public.personal_data_fields_id_seq'::regclass);


--
-- Name: privacy_control_labels id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.privacy_control_labels ALTER COLUMN id SET DEFAULT nextval('public.privacy_control_labels_id_seq'::regclass);


--
-- Name: privacy_sensitivity_levels id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.privacy_sensitivity_levels ALTER COLUMN id SET DEFAULT nextval('public.privacy_sensitivity_levels_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: relationship_types id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.relationship_types ALTER COLUMN id SET DEFAULT nextval('public.relationship_types_id_seq'::regclass);


--
-- Name: relationships id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.relationships ALTER COLUMN id SET DEFAULT nextval('public.relationships_id_seq'::regclass);


--
-- Name: reminders id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.reminders ALTER COLUMN id SET DEFAULT nextval('public.reminders_id_seq'::regclass);


--
-- Name: skills id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.skills ALTER COLUMN id SET DEFAULT nextval('public.skills_id_seq'::regclass);


--
-- Name: tasks id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.tasks ALTER COLUMN id SET DEFAULT nextval('public.tasks_id_seq'::regclass);


--
-- Name: user_privacy_controls id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_controls ALTER COLUMN id SET DEFAULT nextval('public.user_privacy_controls_id_seq'::regclass);


--
-- Name: user_privacy_preferences id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_preferences ALTER COLUMN id SET DEFAULT nextval('public.user_privacy_preferences_id_seq'::regclass);


--
-- Name: work_experiences id; Type: DEFAULT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.work_experiences ALTER COLUMN id SET DEFAULT nextval('public.work_experiences_id_seq'::regclass);


--
-- Data for Name: activities; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.activities (id, user_id, contact_id, activity_type_id, title, description, activity_date, duration_minutes, location, notes, created_at, updated_at) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	6bac22a5-8767-437a-bce3-5302a756f3fe	3	Initial Contact with Michael	First contact after migration from Monica CRM	2025-08-18 12:48:50.862656	30	Virtual	Reconnected after migrating contact data	2025-08-25 12:48:50.862656	2025-08-25 12:48:50.862656
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	6bac22a5-8767-437a-bce3-5302a756f3fe	10	Initial Contact with Michael	First contact after migration from Monica CRM	2025-08-18 12:48:50.862656	30	Virtual	Reconnected after migrating contact data	2025-08-25 12:48:50.862656	2025-08-25 12:48:50.862656
3	5f734504-a6c0-4cdf-b059-836fff8a7e69	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	3	Initial Contact with Beaulah	First contact after migration from Monica CRM	2025-08-18 12:48:50.862656	30	Virtual	Reconnected after migrating contact data	2025-08-25 12:48:50.862656	2025-08-25 12:48:50.862656
\.


--
-- Data for Name: activity_types; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.activity_types (id, name, category, icon, created_at) FROM stdin;
1	Phone Call	call	phone	2025-08-25 12:30:14.489787
2	Meeting	meeting	users	2025-08-25 12:30:14.489787
3	Email	email	mail	2025-08-25 12:30:14.489787
4	Coffee/Lunch	social	coffee	2025-08-25 12:30:14.489787
5	Conference	professional	calendar	2025-08-25 12:30:14.489787
6	Interview	professional	briefcase	2025-08-25 12:30:14.489787
7	Networking Event	professional	network	2025-08-25 12:30:14.489787
8	Phone Call	call	phone	2025-08-25 12:33:07.349584
9	Meeting	meeting	users	2025-08-25 12:33:07.349584
10	Email	email	mail	2025-08-25 12:33:07.349584
11	Coffee/Lunch	social	coffee	2025-08-25 12:33:07.349584
12	Conference	professional	calendar	2025-08-25 12:33:07.349584
13	Interview	professional	briefcase	2025-08-25 12:33:07.349584
14	Networking Event	professional	network	2025-08-25 12:33:07.349584
\.


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.addresses (id, contact_id, type, street, city, state, postal_code, country, is_primary, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ai_embeddings; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.ai_embeddings (id, entity_type, entity_id, embedding_model, embedding_version, embedding_vector, content_hash, content_preview, metadata, created_at, updated_at) FROM stdin;
74ad4bce-4c89-4fe9-8f50-00832d32bf4d	resume	54927ab6-351b-4d19-98bf-3ec8d4855885	text-embedding-ada-002	1.0	{0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1}	abc123	Software Engineer with 5 years experience in Python and JavaScript	\N	2025-08-25 14:21:05.485719	2025-08-25 14:21:05.485719
4cbbb085-385e-4847-bdd2-f53b7f523401	job	9a4ee29c-8ab2-46db-8eb7-1b5428ceb60d	text-embedding-ada-002	1.0	{0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1,0.1}	def456	Senior Software Engineer position requiring Python and JavaScript skills	\N	2025-08-25 14:21:05.485719	2025-08-25 14:21:05.485719
\.


--
-- Data for Name: career_tracking; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.career_tracking (id, user_id, applications_submitted, interviews_scheduled, interviews_completed, offers_received, skills_developed, certifications_earned, networking_events_attended, tracking_date, created_at) FROM stdin;
\.


--
-- Data for Name: career_trajectory; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.career_trajectory (id, user_id, trajectory_type, from_location, to_location, from_industry, to_industry, from_role_level, to_role_level, transition_date, transition_reason, distance_km, salary_change_percentage, created_at) FROM stdin;
\.


--
-- Data for Name: casbin_rule; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.casbin_rule (id, ptype, v0, v1, v2, v3, v4, v5) FROM stdin;
1	p	user	/api/v1/users/profile	GET			
2	p	user	/api/v1/users/profile	PUT			
3	p	user	/api/v1/resumes/*	GET			
4	p	user	/api/v1/resumes/*	POST			
5	p	user	/api/v1/resumes/*	PUT			
6	p	user	/api/v1/resumes/*	DELETE			
7	p	user	/api/v1/jobs/*	GET			
8	p	user	/api/v1/jobs/*	POST			
9	p	user	/api/v1/jobs/*	PUT			
10	p	user	/api/v1/jobs/*	DELETE			
11	p	user	/api/v1/matching/*	GET			
12	p	user	/api/v1/matching/*	POST			
13	p	user	/api/v1/location/*	GET			
14	p	user	/api/v1/location/*	POST			
15	p	vip	/api/v1/contacts/*	GET			
16	p	vip	/api/v1/contacts/*	POST			
17	p	vip	/api/v1/contacts/*	PUT			
18	p	vip	/api/v1/contacts/*	DELETE			
19	p	vip	/api/v1/analytics/*	GET			
20	p	vip	/api/v1/skills/*	GET			
21	p	vip	/api/v1/skills/*	POST			
22	p	admin	/api/v1/admin/*	GET			
23	p	admin	/api/v1/admin/*	POST			
24	p	admin	/api/v1/admin/*	PUT			
25	p	admin	/api/v1/admin/*	DELETE			
26	p	admin	/api/v1/users/*	GET			
27	p	admin	/api/v1/users/*	PUT			
28	p	admin	/api/v1/users/*	DELETE			
29	g	46b12d06-1bc3-4d66-aff1-cedf461e7d50	user				
30	g	d030a74a-3118-435b-99ca-de94708b9f78	user				
31	g	051d26b1-3344-4d55-8878-14b4249c473d	user				
32	g	18cec1df-202a-4b2d-b93b-bab09bfb71fe	user				
33	g	ea406e94-4330-4f98-814a-cf443bcdaa17	user				
34	g	71773331-8733-445d-82d3-51973a583cd5	user				
35	g	054c445a-d710-4aed-a3e5-d3f12484a17c	user				
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.companies (id, name, type, website, industry, size, founded_year, description, logo_url, created_at, updated_at, address_line1, address_line2, city, state, postal_code, country, latitude, longitude, timezone, region) FROM stdin;
\.


--
-- Data for Name: contact_information; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contact_information (id, contact_id, type_id, data, is_primary, created_at, updated_at) FROM stdin;
1	6bac22a5-8767-437a-bce3-5302a756f3fe	1	michael.scott@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
2	6bac22a5-8767-437a-bce3-5302a756f3fe	2	+1-555-6bac	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
3	6bac22a5-8767-437a-bce3-5302a756f3fe	3	linkedin.com/in/michaelscott	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
4	6bac22a5-8767-437a-bce3-5302a756f3fe	7	michael.scott@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
5	6bac22a5-8767-437a-bce3-5302a756f3fe	8	+1-555-6bac	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
6	6bac22a5-8767-437a-bce3-5302a756f3fe	9	linkedin.com/in/michaelscott	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
7	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	1	beaulah.lebsack@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
8	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	2	+1-555-45da	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
9	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	3	linkedin.com/in/beaulahlebsack	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
10	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	7	beaulah.lebsack@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
11	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	8	+1-555-45da	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
12	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	9	linkedin.com/in/beaulahlebsack	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
13	bd412ef5-7fb0-4281-be11-fced0af1dd33	1	loren.connelly@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
14	bd412ef5-7fb0-4281-be11-fced0af1dd33	2	+1-555-bd41	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
15	bd412ef5-7fb0-4281-be11-fced0af1dd33	3	linkedin.com/in/lorenconnelly	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
16	bd412ef5-7fb0-4281-be11-fced0af1dd33	7	loren.connelly@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
17	bd412ef5-7fb0-4281-be11-fced0af1dd33	8	+1-555-bd41	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
18	bd412ef5-7fb0-4281-be11-fced0af1dd33	9	linkedin.com/in/lorenconnelly	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
19	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	1	rosalia.will@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
20	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	2	+1-555-d1d4	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
21	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	3	linkedin.com/in/rosaliawill	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
22	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	7	rosalia.will@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
23	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	8	+1-555-d1d4	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
24	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	9	linkedin.com/in/rosaliawill	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
25	434a5be1-1491-47b8-bdbd-6e851d22412f	1	alivia.wolff@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
26	434a5be1-1491-47b8-bdbd-6e851d22412f	2	+1-555-434a	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
27	434a5be1-1491-47b8-bdbd-6e851d22412f	3	linkedin.com/in/aliviawolff	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
28	434a5be1-1491-47b8-bdbd-6e851d22412f	7	alivia.wolff@example.com	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
29	434a5be1-1491-47b8-bdbd-6e851d22412f	8	+1-555-434a	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
30	434a5be1-1491-47b8-bdbd-6e851d22412f	9	linkedin.com/in/aliviawolff	f	2025-08-25 12:48:50.857166	2025-08-25 12:48:50.857166
\.


--
-- Data for Name: contact_information_types; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contact_information_types (id, name, type, icon, created_at) FROM stdin;
1	Email	email	email	2025-08-25 12:30:14.489028
2	Phone	phone	phone	2025-08-25 12:30:14.489028
3	LinkedIn	social	linkedin	2025-08-25 12:30:14.489028
4	Twitter	social	twitter	2025-08-25 12:30:14.489028
5	GitHub	social	github	2025-08-25 12:30:14.489028
6	Website	website	globe	2025-08-25 12:30:14.489028
7	Email	email	email	2025-08-25 12:33:07.349087
8	Phone	phone	phone	2025-08-25 12:33:07.349087
9	LinkedIn	social	linkedin	2025-08-25 12:33:07.349087
10	Twitter	social	twitter	2025-08-25 12:33:07.349087
11	GitHub	social	github	2025-08-25 12:33:07.349087
12	Website	website	globe	2025-08-25 12:33:07.349087
\.


--
-- Data for Name: contact_recommendations; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contact_recommendations (id, user_id, job_id, contact_id, recommendation_score, relationship_strength, contact_relevance_score, recommendation_reason, is_contacted, contact_date, contact_notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: contact_references; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contact_references (id, user_id, contact_id, relationship_type, can_reference, preferred_contact_method, notes, created_at, updated_at) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	former_colleague	t	email	Migrated from Monica CRM - can provide professional reference	2025-08-25 12:48:50.861837	2025-08-25 12:48:50.861837
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	bd412ef5-7fb0-4281-be11-fced0af1dd33	former_colleague	t	email	Migrated from Monica CRM - can provide professional reference	2025-08-25 12:48:50.861837	2025-08-25 12:48:50.861837
3	5f734504-a6c0-4cdf-b059-836fff8a7e69	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	former_colleague	t	email	Migrated from Monica CRM - can provide professional reference	2025-08-25 12:48:50.861837	2025-08-25 12:48:50.861837
\.


--
-- Data for Name: contacts; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.contacts (id, user_id, first_name, middle_name, last_name, nickname, maiden_name, suffix, prefix, job_position, company_id, avatar_url, notes, is_favorite, is_deleted, created_at, updated_at) FROM stdin;
6bac22a5-8767-437a-bce3-5302a756f3fe	5f734504-a6c0-4cdf-b059-836fff8a7e69	Michael	\N	Scott	\N	\N	\N	\N	Regional Manager	\N	\N	Migrated from Monica CRM	f	f	2025-08-25 12:48:50.852722	2025-08-25 12:48:50.852722
45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	5f734504-a6c0-4cdf-b059-836fff8a7e69	Beaulah	\N	Lebsack	\N	\N	\N	\N	Software Engineer	\N	\N	Migrated from Monica CRM	f	f	2025-08-25 12:48:50.852722	2025-08-25 12:48:50.852722
bd412ef5-7fb0-4281-be11-fced0af1dd33	5f734504-a6c0-4cdf-b059-836fff8a7e69	Loren	\N	Connelly	\N	\N	\N	\N	Product Manager	\N	\N	Migrated from Monica CRM	f	f	2025-08-25 12:48:50.852722	2025-08-25 12:48:50.852722
d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	5f734504-a6c0-4cdf-b059-836fff8a7e69	Rosalia	\N	Will	\N	\N	\N	\N	Data Scientist	\N	\N	Migrated from Monica CRM	f	f	2025-08-25 12:48:50.852722	2025-08-25 12:48:50.852722
434a5be1-1491-47b8-bdbd-6e851d22412f	5f734504-a6c0-4cdf-b059-836fff8a7e69	Alivia	\N	Wolff	\N	\N	\N	\N	UX Designer	\N	\N	Migrated from Monica CRM	f	f	2025-08-25 12:48:50.852722	2025-08-25 12:48:50.852722
\.


--
-- Data for Name: data_access_logs; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.data_access_logs (id, user_id, accessed_user_id, table_name, column_name, access_type, access_reason, ip_address, user_agent, access_timestamp, is_authorized) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	\N	user_privacy_controls	邮箱地址	update	Privacy control updated: CONSENT_REQUIRED = true	\N	\N	2025-08-25 13:58:42.267882	t
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	\N	user_privacy_controls	出生日期	update	Privacy control updated: SENS_HIGH = false	\N	\N	2025-08-25 13:58:42.277308	t
3	750ee6b5-d291-474c-835d-b572cf2be4d4	\N	user_privacy_controls	邮箱地址	update	Privacy control updated: CONSENT_REQUIRED = true	\N	\N	2025-08-25 13:58:42.291376	t
4	750ee6b5-d291-474c-835d-b572cf2be4d4	\N	user_privacy_controls	电话号码	update	Privacy control updated: SENS_HIGH = false	\N	\N	2025-08-25 13:58:42.291376	t
5	750ee6b5-d291-474c-835d-b572cf2be4d4	\N	user_privacy_controls	位置信息	update	Privacy control updated: ACCESS_PRIVATE = true	\N	\N	2025-08-25 13:58:42.291376	t
\.


--
-- Data for Name: data_masking_rules; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.data_masking_rules (id, field_id, masking_type, masking_pattern, replacement_char, start_position, end_position, custom_function, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: database_metadata; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.database_metadata (id, version, name, description, created_at, updated_at) FROM stdin;
1	1.0.0	Zervi	Zervi - 个人关系与职业发展管理平台初始版本 (PostgreSQL)	2025-08-25 04:30:07.646249	2025-08-25 04:30:07.646249
\.


--
-- Data for Name: education; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.education (id, user_id, institution_name, degree, field_of_study, start_date, end_date, gpa, description, achievements, created_at, updated_at, institution_address_line1, institution_address_line2, institution_city, institution_state, institution_postal_code, institution_country, institution_latitude, institution_longitude) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	University of Texas	Bachelor of Science	Computer Science	2012-09-01	2016-05-01	3.70	Focused on algorithms and data structures. Completed capstone project on real-time data processing.	["Dean's List all semesters", "Computer Science Honor Society", "Internship at Microsoft", "Hackathon winner"]	2025-08-25 13:34:47.296949	2025-08-25 13:34:47.296949	\N	\N	\N	\N	\N	\N	\N	\N
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	Stanford University	Master of Science	Computer Science	2016-09-01	2018-06-01	3.80	Specialized in software engineering and distributed systems. Completed thesis on microservices architecture.	["Graduated with honors", "Teaching Assistant for CS101", "Published 2 research papers", "President of CS Graduate Student Association"]	2025-08-25 13:34:47.296949	2025-08-25 13:34:47.296949	\N	\N	\N	\N	\N	\N	\N	\N
3	750ee6b5-d291-474c-835d-b572cf2be4d4	University of Washington	Bachelor of Science	Mathematics	2011-09-01	2015-05-01	3.80	Double major in Mathematics and Statistics. Completed honors thesis on statistical modeling.	["Phi Beta Kappa", "Mathematics Honor Society", "Research internship at Amazon", "Tutoring program coordinator"]	2025-08-25 13:34:47.296949	2025-08-25 13:34:47.296949	\N	\N	\N	\N	\N	\N	\N	\N
4	750ee6b5-d291-474c-835d-b572cf2be4d4	MIT	Master of Science	Data Science	2015-09-01	2017-06-01	3.90	Specialized in machine learning and statistical analysis. Research focused on deep learning applications.	["Graduated summa cum laude", "Research Assistant at CSAIL", "Published 3 papers in top conferences", "MIT Data Science Club President"]	2025-08-25 13:34:47.296949	2025-08-25 13:34:47.296949	\N	\N	\N	\N	\N	\N	\N	\N
5	9ce4ca83-77fd-4f6c-816f-732beb5908a6	University of Michigan	Bachelor of Science	Engineering	2010-09-01	2014-05-01	3.60	Industrial and Operations Engineering with focus on systems optimization.	["Engineering Honor Society", "Student government representative", "Co-op at General Motors", "Engineering project showcase winner"]	2025-08-25 13:34:47.296949	2025-08-25 13:34:47.296949	\N	\N	\N	\N	\N	\N	\N	\N
6	9ce4ca83-77fd-4f6c-816f-732beb5908a6	Harvard Business School	Master of Business Administration	Business Administration	2014-09-01	2016-06-01	3.70	Concentrated in Technology Management and Entrepreneurship. Completed field study in Silicon Valley.	["Baker Scholar", "Technology Club Vice President", "Summer internship at Google", "Business plan competition finalist"]	2025-08-25 13:34:47.296949	2025-08-25 13:34:47.296949	\N	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: field_privacy_controls; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.field_privacy_controls (id, field_id, label_id, control_type, default_value, validation_rules, created_at, updated_at) FROM stdin;
1	4	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
2	5	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
3	6	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
4	7	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
5	8	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
6	9	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
7	11	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
8	12	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
9	13	1	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
10	1	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
11	2	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
12	3	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
13	10	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
14	14	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
15	15	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
16	16	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
17	17	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
18	18	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
19	19	2	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
20	20	3	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
21	21	3	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
22	22	3	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
23	20	4	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
24	21	4	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
25	22	4	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
26	1	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
27	2	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
28	3	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
29	10	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
30	14	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
31	15	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
32	16	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
33	17	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
34	18	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
35	19	5	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
36	4	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
37	5	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
38	6	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
39	7	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
40	8	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
41	9	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
42	11	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
43	12	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
44	13	5	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
45	4	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
46	5	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
47	6	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
48	7	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
49	8	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
50	9	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
51	11	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
52	12	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
53	13	7	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
54	1	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
55	2	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
56	3	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
57	10	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
58	14	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
59	15	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
60	16	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
61	17	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
62	18	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
63	19	8	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
64	20	9	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
65	21	9	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
66	22	9	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
67	4	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
68	5	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
69	6	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
70	7	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
71	8	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
72	9	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
73	11	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
74	12	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
75	13	10	conditional	f	{"consent_required": true, "encryption_required": true}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
76	1	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
77	2	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
78	3	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
79	10	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
80	14	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
81	15	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
82	16	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
83	17	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
84	18	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
85	19	11	optional	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
86	20	12	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
87	21	12	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
88	22	12	required	t	{}	2025-08-25 13:56:55.697872	2025-08-25 13:56:55.697872
\.


--
-- Data for Name: files; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.files (id, user_id, filename, original_filename, file_path, file_size, mime_type, category, description, created_at) FROM stdin;
\.


--
-- Data for Name: job_applications; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.job_applications (id, user_id, job_id, resume_id, application_date, status, notes, follow_up_date, created_at, updated_at) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	ff6df369-0c2c-4dee-98ca-5a7cf5f61f81	54927ab6-351b-4d19-98bf-3ec8d4855885	2025-08-15	interview_scheduled	Technical skills match well, prepare for system design questions. Research Amazon leadership principles.	2025-08-28	2025-08-25 13:47:35.23311	2025-08-25 13:47:35.23311
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	07aa7cc3-437a-4a15-98d6-a7a8b5f696e8	54927ab6-351b-4d19-98bf-3ec8d4855885	2025-08-20	applied	Wait for response	\N	2025-08-25 13:47:35.23311	2025-08-25 13:47:35.23311
3	5f734504-a6c0-4cdf-b059-836fff8a7e69	cfb215f5-a519-40aa-a93b-7db5d7c57db6	54927ab6-351b-4d19-98bf-3ec8d4855885	2025-08-10	applied	Strong technical background, good communication skills. Follow up in 1 week.	2025-09-01	2025-08-25 13:47:35.23311	2025-08-25 13:47:35.23311
\.


--
-- Data for Name: job_embeddings; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.job_embeddings (id, job_id, embedding_type, embedding_model, embedding_vector, content_hash, similarity_threshold, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: job_matches; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.job_matches (job_id, resume_id, overall_score, skills_match_score, experience_match_score, education_match_score, matched_keywords, created_at) FROM stdin;
\.


--
-- Data for Name: jobs; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.jobs (id, user_id, title, company_name, company_id, content, location, employment_type, salary_range, remote_option, application_deadline, source, source_url, status, created_at, updated_at, company_address_line1, company_address_line2, company_city, company_state, company_postal_code, company_country, company_latitude, company_longitude, work_location_type, relocation_required) FROM stdin;
9a4ee29c-8ab2-46db-8eb7-1b5428ceb60d	5f734504-a6c0-4cdf-b059-836fff8a7e69	Senior Software Engineer	Tech Company Inc.	\N	We are looking for a senior software engineer with Python and React experience...	\N	\N	\N	\N	\N	\N	\N	saved	2025-08-25 12:39:37.235752	2025-08-25 12:39:37.235752	\N	\N	\N	\N	\N	\N	\N	\N	office	f
cfb215f5-a519-40aa-a93b-7db5d7c57db6	5f734504-a6c0-4cdf-b059-836fff8a7e69	Senior Software Engineer	Google	\N	Join our team to build scalable systems and innovative products that impact millions of users worldwide. Requirements: 5+ years of software development experience, Strong knowledge of algorithms and data structures, Experience with distributed systems, Proficiency in Java, Python, or Go. Benefits: Competitive salary, Health insurance, 401k matching, Free meals, Flexible work hours.	Mountain View, CA	full_time	$150,000 - $200,000	\N	2025-09-24	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
9287bd7e-769a-490d-8c61-bd22006c7e4f	750ee6b5-d291-474c-835d-b572cf2be4d4	Data Scientist	Netflix	\N	Help us understand user behavior and optimize our recommendation algorithms. Requirements: PhD in Computer Science, Statistics, or related field, Experience with machine learning, Proficiency in Python and SQL, Strong statistical background. Benefits: Competitive salary, Unlimited vacation, Health benefits, Stock options.	Los Gatos, CA	full_time	$130,000 - $180,000	\N	2025-10-09	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
ba726604-aea4-4aed-8a83-4ca0456f7069	9ce4ca83-77fd-4f6c-816f-732beb5908a6	Product Manager	Airbnb	\N	Lead product strategy and development for our core booking platform. Requirements: 3+ years of product management experience, Strong analytical skills, Experience with user research, Technical background preferred. Benefits: Competitive salary, Health insurance, Travel credits, Flexible work arrangements.	San Francisco, CA	full_time	$140,000 - $190,000	\N	2025-10-24	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
07aa7cc3-437a-4a15-98d6-a7a8b5f696e8	5f734504-a6c0-4cdf-b059-836fff8a7e69	Frontend Developer	Spotify	\N	Build beautiful and responsive user interfaces for our music streaming platform. Requirements: 3+ years of frontend development, Proficiency in React, TypeScript, Experience with modern CSS, Understanding of UX principles. Benefits: Competitive salary, Health benefits, Flexible work hours, Music perks.	Stockholm, Sweden	full_time	$80,000 - $120,000	\N	2025-10-04	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
ff6df369-0c2c-4dee-98ca-5a7cf5f61f81	5f734504-a6c0-4cdf-b059-836fff8a7e69	DevOps Engineer	Amazon	\N	Design and maintain our cloud infrastructure and deployment pipelines. Requirements: 4+ years of DevOps experience, Experience with AWS, Knowledge of Docker and Kubernetes, Strong scripting skills. Benefits: Competitive salary, Health insurance, 401k matching, Employee discount.	Seattle, WA	full_time	$120,000 - $160,000	\N	2025-09-29	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
917c096d-b574-48d6-b279-7c2472e69da7	750ee6b5-d291-474c-835d-b572cf2be4d4	Machine Learning Engineer	OpenAI	\N	Work on cutting-edge AI research and development projects. Requirements: MS/PhD in Computer Science or related field, Experience with deep learning frameworks, Strong mathematical background, Research experience preferred. Benefits: Competitive salary, Health insurance, Research opportunities, Conference attendance.	San Francisco, CA	full_time	$160,000 - $220,000	\N	2025-10-14	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
b2d194f1-4457-4b26-b0e0-50bad0c23bab	750ee6b5-d291-474c-835d-b572cf2be4d4	Business Intelligence Analyst	Salesforce	\N	Analyze business data and provide insights to drive strategic decisions. Requirements: 2+ years of BI experience, Proficiency in SQL and Tableau, Strong analytical skills, Business acumen. Benefits: Competitive salary, Health benefits, Professional development, Volunteer time off.	San Francisco, CA	full_time	$90,000 - $130,000	\N	2025-09-19	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
8148bcca-78f1-4002-a5d4-e653689138db	9ce4ca83-77fd-4f6c-816f-732beb5908a6	Senior Product Manager	Microsoft	\N	Lead product development for our cloud services platform. Requirements: 5+ years of product management, Experience with enterprise software, Strong technical background, Leadership experience. Benefits: Competitive salary, Health insurance, Stock options, Professional development.	Redmond, WA	full_time	$150,000 - $200,000	\N	2025-10-19	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
9749dfc5-b460-4b93-be92-1bfae5f6d7fe	9ce4ca83-77fd-4f6c-816f-732beb5908a6	UX Designer	Apple	\N	Design intuitive and beautiful user experiences for our products. Requirements: 4+ years of UX design experience, Portfolio of successful projects, Experience with design tools, Understanding of user research. Benefits: Competitive salary, Health benefits, Product discounts, Creative environment.	Cupertino, CA	full_time	$120,000 - $160,000	\N	2025-09-24	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
cd826352-a4d9-492e-8a37-cc7e70eac7e8	9ce4ca83-77fd-4f6c-816f-732beb5908a6	Engineering Manager	Meta	\N	Lead and grow our engineering team while delivering high-quality products. Requirements: 6+ years of engineering experience, 2+ years of management experience, Strong technical background, Leadership skills. Benefits: Competitive salary, Health insurance, Stock options, Professional development.	Menlo Park, CA	full_time	$180,000 - $250,000	\N	2025-11-03	\N	\N	saved	2025-08-25 13:47:35.229326	2025-08-25 13:47:35.229326	\N	\N	\N	\N	\N	\N	\N	\N	office	f
\.


--
-- Data for Name: location_analytics; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.location_analytics (id, user_id, location_type, city, state, country, latitude, longitude, start_date, end_date, duration_months, is_current, created_at) FROM stdin;
c47c8609-3c2d-466e-853c-b642df6387e1	5f734504-a6c0-4cdf-b059-836fff8a7e69	work	San Francisco	CA	USA	37.77490000	-122.41940000	2020-01-01	2022-06-30	30	f	2025-08-25 14:21:05.487887
091e5f70-8b08-43bb-b4c2-37941548f337	5f734504-a6c0-4cdf-b059-836fff8a7e69	work	New York	NY	USA	40.71280000	-74.00600000	2022-07-01	\N	18	t	2025-08-25 14:21:05.487887
\.


--
-- Data for Name: network_analytics; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.network_analytics (id, user_id, total_contacts, professional_contacts, personal_contacts, strong_relationships, weak_relationships, last_activity_date, networking_score, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notes; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.notes (id, user_id, contact_id, job_id, title, content, category, is_private, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: personal_data_fields; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.personal_data_fields (id, table_name, column_name, field_name, sensitivity_level_id, data_category, description, is_required, is_encrypted, is_masked, created_at, updated_at) FROM stdin;
1	users	email	邮箱地址	2	contact	用户邮箱地址	t	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
2	users	first_name	名字	2	identity	用户名字	t	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
3	users	last_name	姓氏	2	identity	用户姓氏	t	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
4	user_profiles	date_of_birth	出生日期	3	identity	用户出生日期	f	t	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
5	user_profiles	phone	电话号码	3	contact	用户电话号码	f	t	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
6	user_profiles	location	位置信息	3	location	用户位置信息	f	t	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
7	contacts	first_name	联系人名字	3	identity	联系人名字	t	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
8	contacts	last_name	联系人姓氏	3	identity	联系人姓氏	t	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
9	contacts	middle_name	中间名	3	identity	联系人中间名	f	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
10	contacts	nickname	昵称	2	identity	联系人昵称	f	f	f	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
11	contacts	maiden_name	婚前姓氏	3	identity	婚前姓氏	f	t	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
12	contact_information	data	联系数据	3	contact	联系信息数据	t	t	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
13	addresses	street	街道地址	3	location	详细街道地址	f	t	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
14	addresses	city	城市	2	location	城市名称	f	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
15	addresses	province	省份	2	location	省份名称	f	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
16	addresses	postal_code	邮政编码	2	location	邮政编码	f	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
17	work_experiences	company_name	公司名称	2	professional	工作公司名称	t	f	f	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
18	work_experiences	location	工作地点	2	location	工作地点	f	f	t	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
19	education	institution_name	学校名称	2	education	教育机构名称	t	f	f	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
20	jobs	company_name	招聘公司名称	1	professional	招聘公司名称	t	f	f	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
21	jobs	location	职位地点	1	location	职位工作地点	f	f	f	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
22	companies	name	公司名称	1	professional	公司名称	t	f	f	2025-08-25 13:55:02.270554	2025-08-25 13:55:02.270554
\.


--
-- Data for Name: privacy_control_labels; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.privacy_control_labels (id, label_code, label_name, label_type, description, color_code, icon_name, is_active, created_at, updated_at) FROM stdin;
1	SENS_HIGH	高敏感信息	sensitivity	需要最高级别保护的个人信息	#dc3545	shield-exclamation	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
2	SENS_MED	中等敏感信息	sensitivity	需要中等级别保护的个人信息	#ffc107	shield-check	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
3	SENS_LOW	低敏感信息	sensitivity	需要基本保护的个人信息	#28a745	shield	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
4	ACCESS_PUBLIC	公开访问	access	可以公开访问的信息	#17a2b8	globe	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
5	ACCESS_PRIVATE	私有访问	access	仅限个人访问的信息	#6c757d	lock	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
6	ACCESS_SHARED	共享访问	access	可以与他人共享的信息	#fd7e14	share	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
7	CONSENT_REQUIRED	需要同意	consent	需要用户明确同意的信息	#e83e8c	hand-paper	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
8	CONSENT_OPTIONAL	可选同意	consent	用户可选择是否同意的信息	#6f42c1	hand-point-up	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
9	CONSENT_AUTO	自动同意	consent	系统自动同意的信息	#20c997	check-circle	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
10	RETENTION_SHORT	短期保留	retention	短期保留（1年内）	#ffc107	clock	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
11	RETENTION_MEDIUM	中期保留	retention	中期保留（1-3年）	#fd7e14	calendar	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
12	RETENTION_LONG	长期保留	retention	长期保留（3年以上）	#dc3545	archive	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
13	FUNC_ENABLED	功能开启	function	相关功能已开启	#28a745	toggle-on	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
14	FUNC_DISABLED	功能关闭	function	相关功能已关闭	#dc3545	toggle-off	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
15	FUNC_CONDITIONAL	条件开启	function	条件满足时开启	#ffc107	toggle-on	t	2025-08-25 13:56:55.696978	2025-08-25 13:56:55.696978
\.


--
-- Data for Name: privacy_sensitivity_levels; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.privacy_sensitivity_levels (id, level_code, level_name, description, legal_basis, retention_period_months, consent_required, encryption_required, access_logging_required, created_at, updated_at) FROM stdin;
1	P0	公开信息	可以公开访问的非敏感信息	《个人信息保护法》第13条	120	f	f	f	2025-08-25 13:55:02.269802	2025-08-25 13:55:02.269802
2	P1	一般个人信息	基本的个人信息，需要一般保护	《个人信息保护法》第13条	60	t	f	t	2025-08-25 13:55:02.269802	2025-08-25 13:55:02.269802
3	P2	敏感个人信息	敏感的个人信息，需要严格保护	《个人信息保护法》第28条	36	t	t	t	2025-08-25 13:55:02.269802	2025-08-25 13:55:02.269802
4	P3	特殊敏感信息	特殊敏感信息，需要最高级别保护	《个人信息保护法》第28条	24	t	t	t	2025-08-25 13:55:02.269802	2025-08-25 13:55:02.269802
5	P4	禁止收集信息	法律禁止收集的个人信息	《个人信息保护法》第13条	0	f	t	t	2025-08-25 13:55:02.269802	2025-08-25 13:55:02.269802
\.


--
-- Data for Name: processed_jobs; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.processed_jobs (job_id, job_title, company_profile, location, date_posted, employment_type, job_summary, key_responsibilities, qualifications, compensation_and_benefits, application_info, extracted_keywords, processed_at) FROM stdin;
\.


--
-- Data for Name: processed_resumes; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.processed_resumes (resume_id, personal_data, experiences, projects, skills, research_work, achievements, education, certifications, languages, extracted_keywords, processed_at) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.projects (id, user_id, title, description, technologies, start_date, end_date, url, github_url, is_featured, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: relationship_types; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.relationship_types (id, name, category, created_at) FROM stdin;
1	Family	family	2025-08-25 12:30:14.489365
2	Friend	social	2025-08-25 12:30:14.489365
3	Colleague	professional	2025-08-25 12:30:14.489365
4	Former Boss	professional	2025-08-25 12:30:14.489365
5	Client	professional	2025-08-25 12:30:14.489365
6	Mentor	professional	2025-08-25 12:30:14.489365
7	Mentee	professional	2025-08-25 12:30:14.489365
8	Classmate	education	2025-08-25 12:30:14.489365
9	Professor	education	2025-08-25 12:30:14.489365
10	Family	family	2025-08-25 12:33:07.349391
11	Friend	social	2025-08-25 12:33:07.349391
12	Colleague	professional	2025-08-25 12:33:07.349391
13	Former Boss	professional	2025-08-25 12:33:07.349391
14	Client	professional	2025-08-25 12:33:07.349391
15	Mentor	professional	2025-08-25 12:33:07.349391
16	Mentee	professional	2025-08-25 12:33:07.349391
17	Classmate	education	2025-08-25 12:33:07.349391
18	Professor	education	2025-08-25 12:33:07.349391
19	Colleague	professional	2025-08-25 12:47:34.593128
20	Former Colleague	professional	2025-08-25 12:47:34.593128
21	Industry Contact	professional	2025-08-25 12:47:34.593128
22	Friend	social	2025-08-25 12:47:34.593128
23	Mentor	professional	2025-08-25 12:47:34.593128
\.


--
-- Data for Name: relationships; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.relationships (id, user_id, contact_id, relationship_type_id, notes, strength_level, last_contact_date, created_at, updated_at) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	6bac22a5-8767-437a-bce3-5302a756f3fe	3	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	6bac22a5-8767-437a-bce3-5302a756f3fe	12	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
3	5f734504-a6c0-4cdf-b059-836fff8a7e69	6bac22a5-8767-437a-bce3-5302a756f3fe	19	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
4	5f734504-a6c0-4cdf-b059-836fff8a7e69	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	3	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
5	5f734504-a6c0-4cdf-b059-836fff8a7e69	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	12	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
6	5f734504-a6c0-4cdf-b059-836fff8a7e69	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	19	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
7	5f734504-a6c0-4cdf-b059-836fff8a7e69	bd412ef5-7fb0-4281-be11-fced0af1dd33	3	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
8	5f734504-a6c0-4cdf-b059-836fff8a7e69	bd412ef5-7fb0-4281-be11-fced0af1dd33	12	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
9	5f734504-a6c0-4cdf-b059-836fff8a7e69	bd412ef5-7fb0-4281-be11-fced0af1dd33	19	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
10	5f734504-a6c0-4cdf-b059-836fff8a7e69	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	3	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
11	5f734504-a6c0-4cdf-b059-836fff8a7e69	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	12	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
12	5f734504-a6c0-4cdf-b059-836fff8a7e69	d1d4a6f9-a6ba-4b7b-929e-0ba898b47e19	19	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
13	5f734504-a6c0-4cdf-b059-836fff8a7e69	434a5be1-1491-47b8-bdbd-6e851d22412f	3	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
14	5f734504-a6c0-4cdf-b059-836fff8a7e69	434a5be1-1491-47b8-bdbd-6e851d22412f	12	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
15	5f734504-a6c0-4cdf-b059-836fff8a7e69	434a5be1-1491-47b8-bdbd-6e851d22412f	19	Professional relationship from Monica CRM	moderate	2025-07-26	2025-08-25 12:48:50.85887	2025-08-25 12:48:50.85887
\.


--
-- Data for Name: reminders; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.reminders (id, user_id, contact_id, title, description, reminder_date, is_recurring, recurrence_pattern, is_completed, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: resume_embeddings; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.resume_embeddings (id, resume_id, embedding_type, embedding_model, embedding_vector, content_hash, similarity_threshold, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: resume_job_matches; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.resume_job_matches (id, resume_id, job_id, overall_score, skill_match_score, experience_match_score, education_match_score, location_match_score, salary_match_score, culture_match_score, match_details, is_recommended, recommendation_reason, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: resumes; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.resumes (id, user_id, title, content, content_type, version, is_active, created_at, updated_at) FROM stdin;
54927ab6-351b-4d19-98bf-3ec8d4855885	5f734504-a6c0-4cdf-b059-836fff8a7e69	Software Engineer Resume	John Doe - Software Engineer with 5 years experience in Python, JavaScript, and React...	text	1.0	t	2025-08-25 12:39:37.234532	2025-08-25 12:39:37.234532
\.


--
-- Data for Name: skill_embeddings; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.skill_embeddings (id, skill_id, embedding_model, embedding_vector, content_hash, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: skills; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.skills (id, name, category, description, created_at) FROM stdin;
1	Python	technical	Programming language	2025-08-25 12:39:37.237856
2	JavaScript	technical	Programming language	2025-08-25 12:39:37.237856
3	React	technical	Frontend framework	2025-08-25 12:39:37.237856
4	SQL	technical	Database language	2025-08-25 12:39:37.237856
5	Project Management	soft	Leadership skill	2025-08-25 12:39:37.237856
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.tasks (id, user_id, contact_id, title, description, due_date, priority, status, category, created_at, updated_at) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	6bac22a5-8767-437a-bce3-5302a756f3fe	Follow up with Michael	Schedule a coffee chat or virtual meeting	2025-09-01	medium	pending	follow_up	2025-08-25 12:48:50.864241	2025-08-25 12:48:50.864241
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	45da1b0e-3f9c-4ad4-905d-c08eddcd0da3	Follow up with Beaulah	Schedule a coffee chat or virtual meeting	2025-09-01	medium	pending	follow_up	2025-08-25 12:48:50.864241	2025-08-25 12:48:50.864241
\.


--
-- Data for Name: user_privacy_controls; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.user_privacy_controls (id, user_id, field_id, label_id, is_enabled, enabled_date, disabled_date, reason, created_at, updated_at) FROM stdin;
2	750ee6b5-d291-474c-835d-b572cf2be4d4	4	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
3	9ce4ca83-77fd-4f6c-816f-732beb5908a6	4	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
4	5f734504-a6c0-4cdf-b059-836fff8a7e69	5	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
6	9ce4ca83-77fd-4f6c-816f-732beb5908a6	5	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
7	5f734504-a6c0-4cdf-b059-836fff8a7e69	6	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
8	750ee6b5-d291-474c-835d-b572cf2be4d4	6	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
9	9ce4ca83-77fd-4f6c-816f-732beb5908a6	6	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
10	5f734504-a6c0-4cdf-b059-836fff8a7e69	7	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
11	750ee6b5-d291-474c-835d-b572cf2be4d4	7	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
12	9ce4ca83-77fd-4f6c-816f-732beb5908a6	7	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
13	5f734504-a6c0-4cdf-b059-836fff8a7e69	8	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
14	750ee6b5-d291-474c-835d-b572cf2be4d4	8	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
15	9ce4ca83-77fd-4f6c-816f-732beb5908a6	8	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
16	5f734504-a6c0-4cdf-b059-836fff8a7e69	9	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
17	750ee6b5-d291-474c-835d-b572cf2be4d4	9	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
18	9ce4ca83-77fd-4f6c-816f-732beb5908a6	9	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
19	5f734504-a6c0-4cdf-b059-836fff8a7e69	11	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
20	750ee6b5-d291-474c-835d-b572cf2be4d4	11	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
21	9ce4ca83-77fd-4f6c-816f-732beb5908a6	11	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
22	5f734504-a6c0-4cdf-b059-836fff8a7e69	12	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
23	750ee6b5-d291-474c-835d-b572cf2be4d4	12	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
24	9ce4ca83-77fd-4f6c-816f-732beb5908a6	12	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
25	5f734504-a6c0-4cdf-b059-836fff8a7e69	13	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
26	750ee6b5-d291-474c-835d-b572cf2be4d4	13	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
27	9ce4ca83-77fd-4f6c-816f-732beb5908a6	13	1	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
28	5f734504-a6c0-4cdf-b059-836fff8a7e69	1	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
29	750ee6b5-d291-474c-835d-b572cf2be4d4	1	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
30	9ce4ca83-77fd-4f6c-816f-732beb5908a6	1	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
31	5f734504-a6c0-4cdf-b059-836fff8a7e69	2	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
32	750ee6b5-d291-474c-835d-b572cf2be4d4	2	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
33	9ce4ca83-77fd-4f6c-816f-732beb5908a6	2	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
34	5f734504-a6c0-4cdf-b059-836fff8a7e69	3	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
35	750ee6b5-d291-474c-835d-b572cf2be4d4	3	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
36	9ce4ca83-77fd-4f6c-816f-732beb5908a6	3	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
37	5f734504-a6c0-4cdf-b059-836fff8a7e69	10	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
38	750ee6b5-d291-474c-835d-b572cf2be4d4	10	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
39	9ce4ca83-77fd-4f6c-816f-732beb5908a6	10	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
40	5f734504-a6c0-4cdf-b059-836fff8a7e69	14	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
41	750ee6b5-d291-474c-835d-b572cf2be4d4	14	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
42	9ce4ca83-77fd-4f6c-816f-732beb5908a6	14	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
43	5f734504-a6c0-4cdf-b059-836fff8a7e69	15	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
44	750ee6b5-d291-474c-835d-b572cf2be4d4	15	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
45	9ce4ca83-77fd-4f6c-816f-732beb5908a6	15	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
46	5f734504-a6c0-4cdf-b059-836fff8a7e69	16	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
47	750ee6b5-d291-474c-835d-b572cf2be4d4	16	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
48	9ce4ca83-77fd-4f6c-816f-732beb5908a6	16	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
49	5f734504-a6c0-4cdf-b059-836fff8a7e69	17	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
50	750ee6b5-d291-474c-835d-b572cf2be4d4	17	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
51	9ce4ca83-77fd-4f6c-816f-732beb5908a6	17	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
52	5f734504-a6c0-4cdf-b059-836fff8a7e69	18	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
53	750ee6b5-d291-474c-835d-b572cf2be4d4	18	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
54	9ce4ca83-77fd-4f6c-816f-732beb5908a6	18	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
55	5f734504-a6c0-4cdf-b059-836fff8a7e69	19	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
56	750ee6b5-d291-474c-835d-b572cf2be4d4	19	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
57	9ce4ca83-77fd-4f6c-816f-732beb5908a6	19	2	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
58	5f734504-a6c0-4cdf-b059-836fff8a7e69	20	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
59	750ee6b5-d291-474c-835d-b572cf2be4d4	20	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
60	9ce4ca83-77fd-4f6c-816f-732beb5908a6	20	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
61	5f734504-a6c0-4cdf-b059-836fff8a7e69	21	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
62	750ee6b5-d291-474c-835d-b572cf2be4d4	21	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
63	9ce4ca83-77fd-4f6c-816f-732beb5908a6	21	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
64	5f734504-a6c0-4cdf-b059-836fff8a7e69	22	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
65	750ee6b5-d291-474c-835d-b572cf2be4d4	22	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
66	9ce4ca83-77fd-4f6c-816f-732beb5908a6	22	3	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
67	5f734504-a6c0-4cdf-b059-836fff8a7e69	20	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
68	750ee6b5-d291-474c-835d-b572cf2be4d4	20	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
69	9ce4ca83-77fd-4f6c-816f-732beb5908a6	20	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
70	5f734504-a6c0-4cdf-b059-836fff8a7e69	21	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
71	750ee6b5-d291-474c-835d-b572cf2be4d4	21	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
72	9ce4ca83-77fd-4f6c-816f-732beb5908a6	21	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
73	5f734504-a6c0-4cdf-b059-836fff8a7e69	22	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
74	750ee6b5-d291-474c-835d-b572cf2be4d4	22	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
75	9ce4ca83-77fd-4f6c-816f-732beb5908a6	22	4	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
76	5f734504-a6c0-4cdf-b059-836fff8a7e69	1	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
77	750ee6b5-d291-474c-835d-b572cf2be4d4	1	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
5	750ee6b5-d291-474c-835d-b572cf2be4d4	5	1	f	\N	2025-08-25 13:58:42.291376	用户选择不分享	2025-08-25 13:56:55.701666	2025-08-25 13:58:42.291376
78	9ce4ca83-77fd-4f6c-816f-732beb5908a6	1	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
79	5f734504-a6c0-4cdf-b059-836fff8a7e69	2	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
80	750ee6b5-d291-474c-835d-b572cf2be4d4	2	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
81	9ce4ca83-77fd-4f6c-816f-732beb5908a6	2	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
82	5f734504-a6c0-4cdf-b059-836fff8a7e69	3	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
83	750ee6b5-d291-474c-835d-b572cf2be4d4	3	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
84	9ce4ca83-77fd-4f6c-816f-732beb5908a6	3	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
85	5f734504-a6c0-4cdf-b059-836fff8a7e69	10	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
86	750ee6b5-d291-474c-835d-b572cf2be4d4	10	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
87	9ce4ca83-77fd-4f6c-816f-732beb5908a6	10	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
88	5f734504-a6c0-4cdf-b059-836fff8a7e69	14	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
89	750ee6b5-d291-474c-835d-b572cf2be4d4	14	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
90	9ce4ca83-77fd-4f6c-816f-732beb5908a6	14	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
91	5f734504-a6c0-4cdf-b059-836fff8a7e69	15	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
92	750ee6b5-d291-474c-835d-b572cf2be4d4	15	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
93	9ce4ca83-77fd-4f6c-816f-732beb5908a6	15	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
94	5f734504-a6c0-4cdf-b059-836fff8a7e69	16	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
95	750ee6b5-d291-474c-835d-b572cf2be4d4	16	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
96	9ce4ca83-77fd-4f6c-816f-732beb5908a6	16	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
97	5f734504-a6c0-4cdf-b059-836fff8a7e69	17	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
98	750ee6b5-d291-474c-835d-b572cf2be4d4	17	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
99	9ce4ca83-77fd-4f6c-816f-732beb5908a6	17	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
100	5f734504-a6c0-4cdf-b059-836fff8a7e69	18	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
101	750ee6b5-d291-474c-835d-b572cf2be4d4	18	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
102	9ce4ca83-77fd-4f6c-816f-732beb5908a6	18	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
103	5f734504-a6c0-4cdf-b059-836fff8a7e69	19	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
104	750ee6b5-d291-474c-835d-b572cf2be4d4	19	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
105	9ce4ca83-77fd-4f6c-816f-732beb5908a6	19	5	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
106	5f734504-a6c0-4cdf-b059-836fff8a7e69	4	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
107	750ee6b5-d291-474c-835d-b572cf2be4d4	4	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
108	9ce4ca83-77fd-4f6c-816f-732beb5908a6	4	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
109	5f734504-a6c0-4cdf-b059-836fff8a7e69	5	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
110	750ee6b5-d291-474c-835d-b572cf2be4d4	5	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
111	9ce4ca83-77fd-4f6c-816f-732beb5908a6	5	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
112	5f734504-a6c0-4cdf-b059-836fff8a7e69	6	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
114	9ce4ca83-77fd-4f6c-816f-732beb5908a6	6	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
115	5f734504-a6c0-4cdf-b059-836fff8a7e69	7	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
116	750ee6b5-d291-474c-835d-b572cf2be4d4	7	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
117	9ce4ca83-77fd-4f6c-816f-732beb5908a6	7	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
118	5f734504-a6c0-4cdf-b059-836fff8a7e69	8	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
119	750ee6b5-d291-474c-835d-b572cf2be4d4	8	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
120	9ce4ca83-77fd-4f6c-816f-732beb5908a6	8	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
121	5f734504-a6c0-4cdf-b059-836fff8a7e69	9	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
122	750ee6b5-d291-474c-835d-b572cf2be4d4	9	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
123	9ce4ca83-77fd-4f6c-816f-732beb5908a6	9	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
124	5f734504-a6c0-4cdf-b059-836fff8a7e69	11	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
125	750ee6b5-d291-474c-835d-b572cf2be4d4	11	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
126	9ce4ca83-77fd-4f6c-816f-732beb5908a6	11	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
127	5f734504-a6c0-4cdf-b059-836fff8a7e69	12	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
128	750ee6b5-d291-474c-835d-b572cf2be4d4	12	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
129	9ce4ca83-77fd-4f6c-816f-732beb5908a6	12	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
130	5f734504-a6c0-4cdf-b059-836fff8a7e69	13	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
131	750ee6b5-d291-474c-835d-b572cf2be4d4	13	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
132	9ce4ca83-77fd-4f6c-816f-732beb5908a6	13	5	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
133	5f734504-a6c0-4cdf-b059-836fff8a7e69	4	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
134	750ee6b5-d291-474c-835d-b572cf2be4d4	4	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
135	9ce4ca83-77fd-4f6c-816f-732beb5908a6	4	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
136	5f734504-a6c0-4cdf-b059-836fff8a7e69	5	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
137	750ee6b5-d291-474c-835d-b572cf2be4d4	5	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
138	9ce4ca83-77fd-4f6c-816f-732beb5908a6	5	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
139	5f734504-a6c0-4cdf-b059-836fff8a7e69	6	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
140	750ee6b5-d291-474c-835d-b572cf2be4d4	6	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
141	9ce4ca83-77fd-4f6c-816f-732beb5908a6	6	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
142	5f734504-a6c0-4cdf-b059-836fff8a7e69	7	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
143	750ee6b5-d291-474c-835d-b572cf2be4d4	7	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
144	9ce4ca83-77fd-4f6c-816f-732beb5908a6	7	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
145	5f734504-a6c0-4cdf-b059-836fff8a7e69	8	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
146	750ee6b5-d291-474c-835d-b572cf2be4d4	8	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
147	9ce4ca83-77fd-4f6c-816f-732beb5908a6	8	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
148	5f734504-a6c0-4cdf-b059-836fff8a7e69	9	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
149	750ee6b5-d291-474c-835d-b572cf2be4d4	9	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
150	9ce4ca83-77fd-4f6c-816f-732beb5908a6	9	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
151	5f734504-a6c0-4cdf-b059-836fff8a7e69	11	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
152	750ee6b5-d291-474c-835d-b572cf2be4d4	11	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
153	9ce4ca83-77fd-4f6c-816f-732beb5908a6	11	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
154	5f734504-a6c0-4cdf-b059-836fff8a7e69	12	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
155	750ee6b5-d291-474c-835d-b572cf2be4d4	12	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
156	9ce4ca83-77fd-4f6c-816f-732beb5908a6	12	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
157	5f734504-a6c0-4cdf-b059-836fff8a7e69	13	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
158	750ee6b5-d291-474c-835d-b572cf2be4d4	13	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
159	9ce4ca83-77fd-4f6c-816f-732beb5908a6	13	7	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
160	5f734504-a6c0-4cdf-b059-836fff8a7e69	1	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
161	750ee6b5-d291-474c-835d-b572cf2be4d4	1	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
162	9ce4ca83-77fd-4f6c-816f-732beb5908a6	1	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
163	5f734504-a6c0-4cdf-b059-836fff8a7e69	2	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
164	750ee6b5-d291-474c-835d-b572cf2be4d4	2	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
165	9ce4ca83-77fd-4f6c-816f-732beb5908a6	2	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
166	5f734504-a6c0-4cdf-b059-836fff8a7e69	3	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
167	750ee6b5-d291-474c-835d-b572cf2be4d4	3	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
168	9ce4ca83-77fd-4f6c-816f-732beb5908a6	3	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
169	5f734504-a6c0-4cdf-b059-836fff8a7e69	10	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
170	750ee6b5-d291-474c-835d-b572cf2be4d4	10	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
171	9ce4ca83-77fd-4f6c-816f-732beb5908a6	10	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
172	5f734504-a6c0-4cdf-b059-836fff8a7e69	14	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
173	750ee6b5-d291-474c-835d-b572cf2be4d4	14	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
174	9ce4ca83-77fd-4f6c-816f-732beb5908a6	14	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
175	5f734504-a6c0-4cdf-b059-836fff8a7e69	15	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
176	750ee6b5-d291-474c-835d-b572cf2be4d4	15	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
177	9ce4ca83-77fd-4f6c-816f-732beb5908a6	15	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
178	5f734504-a6c0-4cdf-b059-836fff8a7e69	16	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
179	750ee6b5-d291-474c-835d-b572cf2be4d4	16	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
180	9ce4ca83-77fd-4f6c-816f-732beb5908a6	16	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
181	5f734504-a6c0-4cdf-b059-836fff8a7e69	17	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
182	750ee6b5-d291-474c-835d-b572cf2be4d4	17	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
183	9ce4ca83-77fd-4f6c-816f-732beb5908a6	17	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
184	5f734504-a6c0-4cdf-b059-836fff8a7e69	18	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
185	750ee6b5-d291-474c-835d-b572cf2be4d4	18	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
186	9ce4ca83-77fd-4f6c-816f-732beb5908a6	18	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
187	5f734504-a6c0-4cdf-b059-836fff8a7e69	19	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
188	750ee6b5-d291-474c-835d-b572cf2be4d4	19	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
189	9ce4ca83-77fd-4f6c-816f-732beb5908a6	19	8	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
190	5f734504-a6c0-4cdf-b059-836fff8a7e69	20	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
191	750ee6b5-d291-474c-835d-b572cf2be4d4	20	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
192	9ce4ca83-77fd-4f6c-816f-732beb5908a6	20	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
193	5f734504-a6c0-4cdf-b059-836fff8a7e69	21	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
194	750ee6b5-d291-474c-835d-b572cf2be4d4	21	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
195	9ce4ca83-77fd-4f6c-816f-732beb5908a6	21	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
196	5f734504-a6c0-4cdf-b059-836fff8a7e69	22	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
197	750ee6b5-d291-474c-835d-b572cf2be4d4	22	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
198	9ce4ca83-77fd-4f6c-816f-732beb5908a6	22	9	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
199	5f734504-a6c0-4cdf-b059-836fff8a7e69	4	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
200	750ee6b5-d291-474c-835d-b572cf2be4d4	4	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
201	9ce4ca83-77fd-4f6c-816f-732beb5908a6	4	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
202	5f734504-a6c0-4cdf-b059-836fff8a7e69	5	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
203	750ee6b5-d291-474c-835d-b572cf2be4d4	5	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
204	9ce4ca83-77fd-4f6c-816f-732beb5908a6	5	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
205	5f734504-a6c0-4cdf-b059-836fff8a7e69	6	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
206	750ee6b5-d291-474c-835d-b572cf2be4d4	6	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
207	9ce4ca83-77fd-4f6c-816f-732beb5908a6	6	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
208	5f734504-a6c0-4cdf-b059-836fff8a7e69	7	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
209	750ee6b5-d291-474c-835d-b572cf2be4d4	7	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
210	9ce4ca83-77fd-4f6c-816f-732beb5908a6	7	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
211	5f734504-a6c0-4cdf-b059-836fff8a7e69	8	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
212	750ee6b5-d291-474c-835d-b572cf2be4d4	8	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
213	9ce4ca83-77fd-4f6c-816f-732beb5908a6	8	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
214	5f734504-a6c0-4cdf-b059-836fff8a7e69	9	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
215	750ee6b5-d291-474c-835d-b572cf2be4d4	9	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
216	9ce4ca83-77fd-4f6c-816f-732beb5908a6	9	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
217	5f734504-a6c0-4cdf-b059-836fff8a7e69	11	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
218	750ee6b5-d291-474c-835d-b572cf2be4d4	11	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
219	9ce4ca83-77fd-4f6c-816f-732beb5908a6	11	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
220	5f734504-a6c0-4cdf-b059-836fff8a7e69	12	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
221	750ee6b5-d291-474c-835d-b572cf2be4d4	12	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
222	9ce4ca83-77fd-4f6c-816f-732beb5908a6	12	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
223	5f734504-a6c0-4cdf-b059-836fff8a7e69	13	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
224	750ee6b5-d291-474c-835d-b572cf2be4d4	13	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
225	9ce4ca83-77fd-4f6c-816f-732beb5908a6	13	10	f	\N	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
226	5f734504-a6c0-4cdf-b059-836fff8a7e69	1	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
227	750ee6b5-d291-474c-835d-b572cf2be4d4	1	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
228	9ce4ca83-77fd-4f6c-816f-732beb5908a6	1	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
229	5f734504-a6c0-4cdf-b059-836fff8a7e69	2	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
230	750ee6b5-d291-474c-835d-b572cf2be4d4	2	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
231	9ce4ca83-77fd-4f6c-816f-732beb5908a6	2	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
232	5f734504-a6c0-4cdf-b059-836fff8a7e69	3	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
233	750ee6b5-d291-474c-835d-b572cf2be4d4	3	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
234	9ce4ca83-77fd-4f6c-816f-732beb5908a6	3	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
235	5f734504-a6c0-4cdf-b059-836fff8a7e69	10	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
236	750ee6b5-d291-474c-835d-b572cf2be4d4	10	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
237	9ce4ca83-77fd-4f6c-816f-732beb5908a6	10	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
238	5f734504-a6c0-4cdf-b059-836fff8a7e69	14	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
239	750ee6b5-d291-474c-835d-b572cf2be4d4	14	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
240	9ce4ca83-77fd-4f6c-816f-732beb5908a6	14	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
241	5f734504-a6c0-4cdf-b059-836fff8a7e69	15	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
242	750ee6b5-d291-474c-835d-b572cf2be4d4	15	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
243	9ce4ca83-77fd-4f6c-816f-732beb5908a6	15	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
244	5f734504-a6c0-4cdf-b059-836fff8a7e69	16	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
245	750ee6b5-d291-474c-835d-b572cf2be4d4	16	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
246	9ce4ca83-77fd-4f6c-816f-732beb5908a6	16	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
247	5f734504-a6c0-4cdf-b059-836fff8a7e69	17	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
248	750ee6b5-d291-474c-835d-b572cf2be4d4	17	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
249	9ce4ca83-77fd-4f6c-816f-732beb5908a6	17	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
250	5f734504-a6c0-4cdf-b059-836fff8a7e69	18	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
251	750ee6b5-d291-474c-835d-b572cf2be4d4	18	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
252	9ce4ca83-77fd-4f6c-816f-732beb5908a6	18	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
253	5f734504-a6c0-4cdf-b059-836fff8a7e69	19	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
254	750ee6b5-d291-474c-835d-b572cf2be4d4	19	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
255	9ce4ca83-77fd-4f6c-816f-732beb5908a6	19	11	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
256	5f734504-a6c0-4cdf-b059-836fff8a7e69	20	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
257	750ee6b5-d291-474c-835d-b572cf2be4d4	20	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
258	9ce4ca83-77fd-4f6c-816f-732beb5908a6	20	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
259	5f734504-a6c0-4cdf-b059-836fff8a7e69	21	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
260	750ee6b5-d291-474c-835d-b572cf2be4d4	21	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
261	9ce4ca83-77fd-4f6c-816f-732beb5908a6	21	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
262	5f734504-a6c0-4cdf-b059-836fff8a7e69	22	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
263	750ee6b5-d291-474c-835d-b572cf2be4d4	22	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
264	9ce4ca83-77fd-4f6c-816f-732beb5908a6	22	12	t	2025-08-25 13:56:55.701666	\N	\N	2025-08-25 13:56:55.701666	2025-08-25 13:56:55.701666
265	5f734504-a6c0-4cdf-b059-836fff8a7e69	1	7	t	2025-08-25 13:58:42.267882	\N	用户主动同意收集邮箱信息	2025-08-25 13:58:42.267882	2025-08-25 13:58:42.267882
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	4	1	f	\N	2025-08-25 13:58:42.277308	用户选择不分享出生日期	2025-08-25 13:56:55.701666	2025-08-25 13:58:42.277308
267	750ee6b5-d291-474c-835d-b572cf2be4d4	1	7	t	2025-08-25 13:58:42.291376	\N	批量更新测试	2025-08-25 13:58:42.291376	2025-08-25 13:58:42.291376
113	750ee6b5-d291-474c-835d-b572cf2be4d4	6	5	t	2025-08-25 13:58:42.291376	\N	允许位置服务	2025-08-25 13:56:55.701666	2025-08-25 13:58:42.291376
\.


--
-- Data for Name: user_privacy_preferences; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.user_privacy_preferences (id, user_id, field_id, is_enabled, consent_given, consent_date, consent_version, data_usage_purposes, retention_consent, sharing_consent, created_at, updated_at) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	1	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
2	750ee6b5-d291-474c-835d-b572cf2be4d4	1	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
3	9ce4ca83-77fd-4f6c-816f-732beb5908a6	1	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
4	5f734504-a6c0-4cdf-b059-836fff8a7e69	2	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
5	750ee6b5-d291-474c-835d-b572cf2be4d4	2	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
6	9ce4ca83-77fd-4f6c-816f-732beb5908a6	2	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
7	5f734504-a6c0-4cdf-b059-836fff8a7e69	3	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
8	750ee6b5-d291-474c-835d-b572cf2be4d4	3	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
9	9ce4ca83-77fd-4f6c-816f-732beb5908a6	3	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
10	5f734504-a6c0-4cdf-b059-836fff8a7e69	4	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
11	750ee6b5-d291-474c-835d-b572cf2be4d4	4	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
12	9ce4ca83-77fd-4f6c-816f-732beb5908a6	4	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
13	5f734504-a6c0-4cdf-b059-836fff8a7e69	5	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
14	750ee6b5-d291-474c-835d-b572cf2be4d4	5	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
15	9ce4ca83-77fd-4f6c-816f-732beb5908a6	5	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
16	5f734504-a6c0-4cdf-b059-836fff8a7e69	6	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
17	750ee6b5-d291-474c-835d-b572cf2be4d4	6	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
18	9ce4ca83-77fd-4f6c-816f-732beb5908a6	6	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
19	5f734504-a6c0-4cdf-b059-836fff8a7e69	7	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
20	750ee6b5-d291-474c-835d-b572cf2be4d4	7	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
21	9ce4ca83-77fd-4f6c-816f-732beb5908a6	7	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
22	5f734504-a6c0-4cdf-b059-836fff8a7e69	8	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
23	750ee6b5-d291-474c-835d-b572cf2be4d4	8	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
24	9ce4ca83-77fd-4f6c-816f-732beb5908a6	8	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
25	5f734504-a6c0-4cdf-b059-836fff8a7e69	9	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
26	750ee6b5-d291-474c-835d-b572cf2be4d4	9	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
27	9ce4ca83-77fd-4f6c-816f-732beb5908a6	9	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
28	5f734504-a6c0-4cdf-b059-836fff8a7e69	10	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
29	750ee6b5-d291-474c-835d-b572cf2be4d4	10	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
30	9ce4ca83-77fd-4f6c-816f-732beb5908a6	10	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
31	5f734504-a6c0-4cdf-b059-836fff8a7e69	11	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
32	750ee6b5-d291-474c-835d-b572cf2be4d4	11	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
33	9ce4ca83-77fd-4f6c-816f-732beb5908a6	11	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
34	5f734504-a6c0-4cdf-b059-836fff8a7e69	12	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
35	750ee6b5-d291-474c-835d-b572cf2be4d4	12	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
36	9ce4ca83-77fd-4f6c-816f-732beb5908a6	12	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
37	5f734504-a6c0-4cdf-b059-836fff8a7e69	13	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
38	750ee6b5-d291-474c-835d-b572cf2be4d4	13	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
39	9ce4ca83-77fd-4f6c-816f-732beb5908a6	13	f	f	\N	1.0	["personal_management", "career_development", "job_search"]	f	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
40	5f734504-a6c0-4cdf-b059-836fff8a7e69	14	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
41	750ee6b5-d291-474c-835d-b572cf2be4d4	14	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
42	9ce4ca83-77fd-4f6c-816f-732beb5908a6	14	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
43	5f734504-a6c0-4cdf-b059-836fff8a7e69	15	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
44	750ee6b5-d291-474c-835d-b572cf2be4d4	15	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
45	9ce4ca83-77fd-4f6c-816f-732beb5908a6	15	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
46	5f734504-a6c0-4cdf-b059-836fff8a7e69	16	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
47	750ee6b5-d291-474c-835d-b572cf2be4d4	16	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
48	9ce4ca83-77fd-4f6c-816f-732beb5908a6	16	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
49	5f734504-a6c0-4cdf-b059-836fff8a7e69	17	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
50	750ee6b5-d291-474c-835d-b572cf2be4d4	17	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
51	9ce4ca83-77fd-4f6c-816f-732beb5908a6	17	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
52	5f734504-a6c0-4cdf-b059-836fff8a7e69	18	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
53	750ee6b5-d291-474c-835d-b572cf2be4d4	18	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
54	9ce4ca83-77fd-4f6c-816f-732beb5908a6	18	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
55	5f734504-a6c0-4cdf-b059-836fff8a7e69	19	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
56	750ee6b5-d291-474c-835d-b572cf2be4d4	19	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
57	9ce4ca83-77fd-4f6c-816f-732beb5908a6	19	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	f	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
58	5f734504-a6c0-4cdf-b059-836fff8a7e69	20	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
59	750ee6b5-d291-474c-835d-b572cf2be4d4	20	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
60	9ce4ca83-77fd-4f6c-816f-732beb5908a6	20	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
61	5f734504-a6c0-4cdf-b059-836fff8a7e69	21	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
62	750ee6b5-d291-474c-835d-b572cf2be4d4	21	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
63	9ce4ca83-77fd-4f6c-816f-732beb5908a6	21	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
64	5f734504-a6c0-4cdf-b059-836fff8a7e69	22	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
65	750ee6b5-d291-474c-835d-b572cf2be4d4	22	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
66	9ce4ca83-77fd-4f6c-816f-732beb5908a6	22	t	t	2025-08-25 13:55:02.27301	1.0	["personal_management", "career_development", "job_search"]	t	t	2025-08-25 13:55:02.27301	2025-08-25 13:55:02.27301
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.user_profiles (user_id, avatar_url, bio, location, website, linkedin_url, github_url, twitter_url, phone, date_of_birth, gender_id, created_at, updated_at) FROM stdin;
750ee6b5-d291-474c-835d-b572cf2be4d4	https://via.placeholder.com/150/4A90E2/FFFFFF?text=JS	Data scientist and machine learning specialist with expertise in Python, TensorFlow, and statistical analysis.	New York, NY	https://janesmith.ai	https://linkedin.com/in/janesmith	https://github.com/janesmith	https://twitter.com/janesmith	+1-555-0102	1988-07-22	\N	2025-08-25 12:43:09.506725	2025-08-25 12:43:09.506725
9ce4ca83-77fd-4f6c-816f-732beb5908a6	https://via.placeholder.com/150/4A90E2/FFFFFF?text=BW	Product manager with 10+ years experience in SaaS product development and team leadership.	Seattle, WA	https://bobwilson.com	https://linkedin.com/in/bobwilson	https://github.com/bobwilson	https://twitter.com/bobwilson	+1-555-0103	1985-11-08	\N	2025-08-25 12:43:09.506725	2025-08-25 12:43:09.506725
5f734504-a6c0-4cdf-b059-836fff8a7e69	https://via.placeholder.com/150/4A90E2/FFFFFF?text=JD	Experienced software engineer with 5+ years in full-stack development. Passionate about Python, React, and building scalable applications.	San Francisco, CA	https://johndoe.dev	https://linkedin.com/in/johndoe	https://github.com/johndoe	https://twitter.com/johndoe	+1-555-0123	1990-03-15	\N	2025-08-25 12:43:09.506725	2025-08-25 12:43:09.506725
\.


--
-- Data for Name: user_skills; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.user_skills (user_id, skill_id, proficiency_level, years_of_experience, is_primary, created_at, updated_at) FROM stdin;
5f734504-a6c0-4cdf-b059-836fff8a7e69	1	advanced	3	t	2025-08-25 12:39:37.238964	2025-08-25 12:39:37.238964
750ee6b5-d291-474c-835d-b572cf2be4d4	1	expert	6	t	2025-08-25 13:38:19.576106	2025-08-25 13:38:19.576106
5f734504-a6c0-4cdf-b059-836fff8a7e69	2	advanced	4	f	2025-08-25 13:38:19.576106	2025-08-25 13:38:19.576106
9ce4ca83-77fd-4f6c-816f-732beb5908a6	4	intermediate	2	f	2025-08-25 13:38:19.576106	2025-08-25 13:38:19.576106
750ee6b5-d291-474c-835d-b572cf2be4d4	4	expert	5	f	2025-08-25 13:38:19.576106	2025-08-25 13:38:19.576106
5f734504-a6c0-4cdf-b059-836fff8a7e69	4	advanced	6	f	2025-08-25 13:38:19.576106	2025-08-25 13:38:19.576106
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.users (id, email, first_name, last_name, password, two_factor_secret, two_factor_recovery_codes, two_factor_confirmed_at, email_verified_at, name_order, date_format, timezone, locale, is_administrator, created_at, updated_at, deleted_at, password_hash, phone, is_active, date_of_birth, gender, profile_picture, last_login_at) FROM stdin;
5f734504-a6c0-4cdf-b059-836fff8a7e69	john.doe@example.com	John	Doe	\N	\N	\N	\N	\N	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-25 12:39:37.230866+08	2025-08-25 12:39:37.230866+08	\N	\N	\N	t	\N	\N	\N	\N
750ee6b5-d291-474c-835d-b572cf2be4d4	jane.smith@example.com	Jane	Smith	\N	\N	\N	\N	\N	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-25 12:39:37.230866+08	2025-08-25 12:39:37.230866+08	\N	\N	\N	t	\N	\N	\N	\N
9ce4ca83-77fd-4f6c-816f-732beb5908a6	bob.wilson@example.com	Bob	Wilson	\N	\N	\N	\N	\N	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-25 12:39:37.230866+08	2025-08-25 12:39:37.230866+08	\N	\N	\N	t	\N	\N	\N	\N
d030a74a-3118-435b-99ca-de94708b9f78	e2e-test@example.com	E2E	Test	\N	\N	\N	\N	0001-01-01 00:00:00	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-25 23:01:41.752068+08	2025-08-25 23:01:41.82356+08	\N	$2a$10$.Hh1QRaKah.h7BfVeixmA.v.yCzsa/zcTKg2e03X2llXjndrg9VHW		t	0001-01-01 00:00:00			2025-08-25 23:01:41.823334
051d26b1-3344-4d55-8878-14b4249c473d	e2e-test-1756134364@example.com	E2E	Test	\N	\N	\N	\N	0001-01-01 00:00:00	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-25 23:06:04.567395+08	2025-08-25 23:06:04.636585+08	\N	$2a$10$sz7HkjL.h3W224wkJAaNQeyoWwmNlRQyV.VukFpbVa5Pj2GKDDEpa		t	0001-01-01 00:00:00			2025-08-25 23:06:04.636364
18cec1df-202a-4b2d-b93b-bab09bfb71fe	miniprogram-test@example.com	小程序	测试用户	\N	\N	\N	\N	0001-01-01 00:00:00	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-26 06:22:04.697229+08	2025-08-26 06:22:04.697229+08	\N	$2a$10$uQHQybrn7xYscnHBTtkOPuoPmKXaRce9Uheci4sIooXCqX3O9q7m6		t	0001-01-01 00:00:00			0001-01-01 00:00:00
46b12d06-1bc3-4d66-aff1-cedf461e7d50	test@example.com	测试	用户	\N	\N	\N	\N	0001-01-01 00:00:00	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-25 22:44:36.130116+08	2025-08-26 06:22:31.176112+08	\N	$2a$10$QSj436ZdJI6YtT3PCzQUKu2WgXHoAyHnbz5YNdhPvzwQ3zLRpaVFm		t	0001-01-01 00:00:00			2025-08-26 06:22:31.175818
ea406e94-4330-4f98-814a-cf443bcdaa17	miniprogram-simulation@example.com	小程序	仿真用户	\N	\N	\N	\N	0001-01-01 00:00:00	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-26 06:25:17.257399+08	2025-08-26 06:25:17.339023+08	\N	$2a$10$6dgWbO6LeEVT0MzG.ebmaewTtUwnMWepYVWqCi4vhNym0XPSxMqzG		t	0001-01-01 00:00:00			2025-08-26 06:25:17.338762
71773331-8733-445d-82d3-51973a583cd5	comprehensive-test@example.com	全面测试	用户	\N	\N	\N	\N	0001-01-01 00:00:00	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-26 06:35:18.345102+08	2025-08-26 06:35:18.425948+08	\N	$2a$10$JkchVCn37r0spCkpQDjxU.t1kcS3ZcogkQHFerfW6BDoksOWHiMq.		t	0001-01-01 00:00:00			2025-08-26 06:35:18.425626
054c445a-d710-4aed-a3e5-d3f12484a17c	test_ai_matching@example.com	Test	User	\N	\N	\N	\N	0001-01-01 00:00:00	%first_name% %last_name%	MMM DD, YYYY	UTC	en	f	2025-08-26 14:48:23.268388+08	2025-08-26 15:16:09.982116+08	\N	$2a$10$CJ8FqzAcuujEF838Lv17GOI9ul1I8rI8WDt1zR78Ybna.V/928dyO		t	0001-01-01 00:00:00			2025-08-26 15:16:09.981849
\.


--
-- Data for Name: work_experiences; Type: TABLE DATA; Schema: public; Owner: szjason72
--

COPY public.work_experiences (id, user_id, company_name, company_id, job_title, start_date, end_date, is_current, description, achievements, skills_used, location, created_at, updated_at, company_address_line1, company_address_line2, company_city, company_state, company_postal_code, company_country, company_latitude, company_longitude, work_location_type, relocation_required) FROM stdin;
1	5f734504-a6c0-4cdf-b059-836fff8a7e69	StartupXYZ	\N	Full Stack Developer	2018-06-01	2020-02-28	f	Built MVP for fintech startup from scratch. Handled both frontend and backend development.	["Launched product in 6 months", "Secured $2M funding", "Grew user base to 10K+"]	["React", "Node.js", "MongoDB", "AWS", "Stripe API"]	Austin, TX	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
2	5f734504-a6c0-4cdf-b059-836fff8a7e69	DataFlow Analytics	\N	Software Engineer	2020-03-01	2021-12-31	f	Developed data processing pipelines and machine learning models for customer analytics. Worked with big data technologies.	["Built real-time analytics dashboard", "Improved data processing speed by 50%", "Published 2 technical papers"]	["Python", "Apache Spark", "TensorFlow", "PostgreSQL", "Redis"]	Seattle, WA	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
3	5f734504-a6c0-4cdf-b059-836fff8a7e69	TechCorp Inc.	\N	Senior Software Engineer	2022-01-15	\N	t	Lead development of microservices architecture for e-commerce platform. Managed team of 5 developers and implemented CI/CD pipelines.	["Increased system performance by 40%", "Reduced deployment time by 60%", "Mentored 3 junior developers"]	["Java", "Spring Boot", "Docker", "Kubernetes", "AWS", "Microservices"]	San Francisco, CA	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
4	750ee6b5-d291-474c-835d-b572cf2be4d4	InnovateSoft	\N	Data Scientist	2017-08-01	2019-04-30	f	Developed recommendation systems and customer segmentation models for SaaS platform.	["Increased user engagement by 25%", "Built real-time recommendation engine", "Reduced churn by 15%"]	["Python", "Scikit-learn", "Pandas", "NumPy", "A/B Testing"]	Boston, MA	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
5	750ee6b5-d291-474c-835d-b572cf2be4d4	Global Solutions	\N	Senior Data Analyst	2019-05-01	2020-12-31	f	Conducted advanced analytics for Fortune 500 clients. Developed statistical models and created executive dashboards.	["Generated $5M in revenue insights", "Automated 80% of reporting", "Presented to C-level executives"]	["R", "SQL", "Tableau", "Power BI", "Statistical Analysis"]	New York, NY	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
6	750ee6b5-d291-474c-835d-b572cf2be4d4	DataFlow Analytics	\N	Lead Data Scientist	2021-01-01	\N	t	Lead data science team developing ML models for predictive analytics. Manage 8 data scientists and collaborate with product teams.	["Improved prediction accuracy by 35%", "Reduced model training time by 70%", "Led 5 successful ML projects"]	["Python", "TensorFlow", "PyTorch", "Apache Spark", "Kubernetes", "MLops"]	Seattle, WA	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
7	9ce4ca83-77fd-4f6c-816f-732beb5908a6	Global Solutions	\N	Product Manager	2016-01-01	2018-02-28	f	Managed product lifecycle for consulting services. Developed go-to-market strategies and customer success programs.	["Grew client base by 300%", "Improved client retention to 90%", "Launched 2 new service lines"]	["Consulting", "Client Management", "Business Development", "Process Improvement"]	Chicago, IL	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
8	9ce4ca83-77fd-4f6c-816f-732beb5908a6	TechCorp Inc.	\N	Senior Product Manager	2018-03-01	2020-08-31	f	Managed product development for enterprise software solutions. Led teams of 15+ engineers and designers.	["Delivered 5 major product releases", "Increased market share by 20%", "Reduced time-to-market by 40%"]	["Product Management", "User Experience", "Market Research", "Technical Architecture"]	San Francisco, CA	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
9	9ce4ca83-77fd-4f6c-816f-732beb5908a6	InnovateSoft	\N	Product Manager	2020-09-01	\N	t	Lead product strategy and development for B2B SaaS platform. Manage product roadmap and cross-functional teams.	["Increased ARR by 150%", "Launched 3 major features", "Improved customer satisfaction to 95%"]	["Product Strategy", "Agile", "User Research", "Data Analysis", "Stakeholder Management"]	Boston, MA	2025-08-25 13:32:57.828594	2025-08-25 13:32:57.828594	\N	\N	\N	\N	\N	\N	\N	\N	office	f
\.


--
-- Name: activities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.activities_id_seq', 3, true);


--
-- Name: activity_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.activity_types_id_seq', 14, true);


--
-- Name: addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.addresses_id_seq', 1, false);


--
-- Name: career_tracking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.career_tracking_id_seq', 1, false);


--
-- Name: casbin_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.casbin_rule_id_seq', 35, true);


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.companies_id_seq', 1, false);


--
-- Name: contact_information_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.contact_information_id_seq', 30, true);


--
-- Name: contact_information_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.contact_information_types_id_seq', 12, true);


--
-- Name: contact_references_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.contact_references_id_seq', 3, true);


--
-- Name: data_access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.data_access_logs_id_seq', 5, true);


--
-- Name: data_masking_rules_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.data_masking_rules_id_seq', 1, false);


--
-- Name: database_metadata_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.database_metadata_id_seq', 1, true);


--
-- Name: education_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.education_id_seq', 6, true);


--
-- Name: field_privacy_controls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.field_privacy_controls_id_seq', 88, true);


--
-- Name: files_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.files_id_seq', 1, false);


--
-- Name: job_applications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.job_applications_id_seq', 3, true);


--
-- Name: network_analytics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.network_analytics_id_seq', 1, false);


--
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.notes_id_seq', 1, false);


--
-- Name: personal_data_fields_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.personal_data_fields_id_seq', 22, true);


--
-- Name: privacy_control_labels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.privacy_control_labels_id_seq', 15, true);


--
-- Name: privacy_sensitivity_levels_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.privacy_sensitivity_levels_id_seq', 5, true);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.projects_id_seq', 1, false);


--
-- Name: relationship_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.relationship_types_id_seq', 23, true);


--
-- Name: relationships_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.relationships_id_seq', 15, true);


--
-- Name: reminders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.reminders_id_seq', 1, false);


--
-- Name: skills_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.skills_id_seq', 5, true);


--
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.tasks_id_seq', 2, true);


--
-- Name: user_privacy_controls_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.user_privacy_controls_id_seq', 269, true);


--
-- Name: user_privacy_preferences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.user_privacy_preferences_id_seq', 66, true);


--
-- Name: work_experiences_id_seq; Type: SEQUENCE SET; Schema: public; Owner: szjason72
--

SELECT pg_catalog.setval('public.work_experiences_id_seq', 9, true);


--
-- Name: activities activities_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_pkey PRIMARY KEY (id);


--
-- Name: activity_types activity_types_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.activity_types
    ADD CONSTRAINT activity_types_pkey PRIMARY KEY (id);


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: ai_embeddings ai_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.ai_embeddings
    ADD CONSTRAINT ai_embeddings_pkey PRIMARY KEY (id);


--
-- Name: career_tracking career_tracking_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.career_tracking
    ADD CONSTRAINT career_tracking_pkey PRIMARY KEY (id);


--
-- Name: career_trajectory career_trajectory_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.career_trajectory
    ADD CONSTRAINT career_trajectory_pkey PRIMARY KEY (id);


--
-- Name: casbin_rule casbin_rule_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.casbin_rule
    ADD CONSTRAINT casbin_rule_pkey PRIMARY KEY (id);


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
-- Name: contact_recommendations contact_recommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_recommendations
    ADD CONSTRAINT contact_recommendations_pkey PRIMARY KEY (id);


--
-- Name: contact_references contact_references_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_references
    ADD CONSTRAINT contact_references_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: data_access_logs data_access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.data_access_logs
    ADD CONSTRAINT data_access_logs_pkey PRIMARY KEY (id);


--
-- Name: data_masking_rules data_masking_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.data_masking_rules
    ADD CONSTRAINT data_masking_rules_pkey PRIMARY KEY (id);


--
-- Name: database_metadata database_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.database_metadata
    ADD CONSTRAINT database_metadata_pkey PRIMARY KEY (id);


--
-- Name: education education_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.education
    ADD CONSTRAINT education_pkey PRIMARY KEY (id);


--
-- Name: field_privacy_controls field_privacy_controls_field_id_label_id_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.field_privacy_controls
    ADD CONSTRAINT field_privacy_controls_field_id_label_id_key UNIQUE (field_id, label_id);


--
-- Name: field_privacy_controls field_privacy_controls_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.field_privacy_controls
    ADD CONSTRAINT field_privacy_controls_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: job_applications job_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_applications
    ADD CONSTRAINT job_applications_pkey PRIMARY KEY (id);


--
-- Name: job_embeddings job_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_embeddings
    ADD CONSTRAINT job_embeddings_pkey PRIMARY KEY (id);


--
-- Name: job_matches job_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_matches
    ADD CONSTRAINT job_matches_pkey PRIMARY KEY (job_id, resume_id);


--
-- Name: jobs jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_pkey PRIMARY KEY (id);


--
-- Name: location_analytics location_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.location_analytics
    ADD CONSTRAINT location_analytics_pkey PRIMARY KEY (id);


--
-- Name: network_analytics network_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.network_analytics
    ADD CONSTRAINT network_analytics_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: personal_data_fields personal_data_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.personal_data_fields
    ADD CONSTRAINT personal_data_fields_pkey PRIMARY KEY (id);


--
-- Name: personal_data_fields personal_data_fields_table_name_column_name_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.personal_data_fields
    ADD CONSTRAINT personal_data_fields_table_name_column_name_key UNIQUE (table_name, column_name);


--
-- Name: privacy_control_labels privacy_control_labels_label_code_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.privacy_control_labels
    ADD CONSTRAINT privacy_control_labels_label_code_key UNIQUE (label_code);


--
-- Name: privacy_control_labels privacy_control_labels_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.privacy_control_labels
    ADD CONSTRAINT privacy_control_labels_pkey PRIMARY KEY (id);


--
-- Name: privacy_sensitivity_levels privacy_sensitivity_levels_level_code_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.privacy_sensitivity_levels
    ADD CONSTRAINT privacy_sensitivity_levels_level_code_key UNIQUE (level_code);


--
-- Name: privacy_sensitivity_levels privacy_sensitivity_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.privacy_sensitivity_levels
    ADD CONSTRAINT privacy_sensitivity_levels_pkey PRIMARY KEY (id);


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
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: relationship_types relationship_types_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.relationship_types
    ADD CONSTRAINT relationship_types_pkey PRIMARY KEY (id);


--
-- Name: relationships relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_pkey PRIMARY KEY (id);


--
-- Name: reminders reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.reminders
    ADD CONSTRAINT reminders_pkey PRIMARY KEY (id);


--
-- Name: resume_embeddings resume_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resume_embeddings
    ADD CONSTRAINT resume_embeddings_pkey PRIMARY KEY (id);


--
-- Name: resume_job_matches resume_job_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resume_job_matches
    ADD CONSTRAINT resume_job_matches_pkey PRIMARY KEY (id);


--
-- Name: resume_job_matches resume_job_matches_resume_id_job_id_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resume_job_matches
    ADD CONSTRAINT resume_job_matches_resume_id_job_id_key UNIQUE (resume_id, job_id);


--
-- Name: resumes resumes_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resumes
    ADD CONSTRAINT resumes_pkey PRIMARY KEY (id);


--
-- Name: skill_embeddings skill_embeddings_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.skill_embeddings
    ADD CONSTRAINT skill_embeddings_pkey PRIMARY KEY (id);


--
-- Name: skills skills_name_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_name_key UNIQUE (name);


--
-- Name: skills skills_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.skills
    ADD CONSTRAINT skills_pkey PRIMARY KEY (id);


--
-- Name: tasks tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_pkey PRIMARY KEY (id);


--
-- Name: user_privacy_controls user_privacy_controls_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_controls
    ADD CONSTRAINT user_privacy_controls_pkey PRIMARY KEY (id);


--
-- Name: user_privacy_controls user_privacy_controls_user_id_field_id_label_id_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_controls
    ADD CONSTRAINT user_privacy_controls_user_id_field_id_label_id_key UNIQUE (user_id, field_id, label_id);


--
-- Name: user_privacy_preferences user_privacy_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_preferences
    ADD CONSTRAINT user_privacy_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_privacy_preferences user_privacy_preferences_user_id_field_id_key; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_preferences
    ADD CONSTRAINT user_privacy_preferences_user_id_field_id_key UNIQUE (user_id, field_id);


--
-- Name: user_profiles user_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: user_skills user_skills_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT user_skills_pkey PRIMARY KEY (user_id, skill_id);


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
-- Name: work_experiences work_experiences_pkey; Type: CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.work_experiences
    ADD CONSTRAINT work_experiences_pkey PRIMARY KEY (id);


--
-- Name: idx_activities_contact_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_activities_contact_id ON public.activities USING btree (contact_id);


--
-- Name: idx_activities_date; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_activities_date ON public.activities USING btree (activity_date);


--
-- Name: idx_activities_user_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_activities_user_id ON public.activities USING btree (user_id);


--
-- Name: idx_ai_embeddings_content_hash; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_ai_embeddings_content_hash ON public.ai_embeddings USING btree (content_hash);


--
-- Name: idx_ai_embeddings_entity; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_ai_embeddings_entity ON public.ai_embeddings USING btree (entity_type, entity_id);


--
-- Name: idx_ai_embeddings_model; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_ai_embeddings_model ON public.ai_embeddings USING btree (embedding_model, embedding_version);


--
-- Name: idx_career_trajectory_user_type; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_career_trajectory_user_type ON public.career_trajectory USING btree (user_id, trajectory_type);


--
-- Name: idx_casbin_rule; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE UNIQUE INDEX idx_casbin_rule ON public.casbin_rule USING btree (ptype, v0, v1, v2, v3, v4, v5);


--
-- Name: idx_companies_location; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_companies_location ON public.companies USING btree (latitude, longitude);


--
-- Name: idx_contact_recommendations_score; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_contact_recommendations_score ON public.contact_recommendations USING btree (recommendation_score DESC);


--
-- Name: idx_contacts_company_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_contacts_company_id ON public.contacts USING btree (company_id);


--
-- Name: idx_contacts_created_at; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_contacts_created_at ON public.contacts USING btree (created_at);


--
-- Name: idx_contacts_name; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_contacts_name ON public.contacts USING btree (first_name, last_name);


--
-- Name: idx_contacts_user_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_contacts_user_id ON public.contacts USING btree (user_id);


--
-- Name: idx_data_access_logs_timestamp; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_data_access_logs_timestamp ON public.data_access_logs USING btree (access_timestamp);


--
-- Name: idx_data_access_logs_user; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_data_access_logs_user ON public.data_access_logs USING btree (user_id, accessed_user_id);


--
-- Name: idx_education_location; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_education_location ON public.education USING btree (institution_latitude, institution_longitude);


--
-- Name: idx_field_privacy_controls_field_label; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_field_privacy_controls_field_label ON public.field_privacy_controls USING btree (field_id, label_id);


--
-- Name: idx_job_applications_job_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_job_applications_job_id ON public.job_applications USING btree (job_id);


--
-- Name: idx_job_applications_status; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_job_applications_status ON public.job_applications USING btree (status);


--
-- Name: idx_job_applications_user_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_job_applications_user_id ON public.job_applications USING btree (user_id);


--
-- Name: idx_jobs_company_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_jobs_company_id ON public.jobs USING btree (company_id);


--
-- Name: idx_jobs_created_at; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_jobs_created_at ON public.jobs USING btree (created_at);


--
-- Name: idx_jobs_location; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_jobs_location ON public.jobs USING btree (company_latitude, company_longitude);


--
-- Name: idx_jobs_status; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_jobs_status ON public.jobs USING btree (status);


--
-- Name: idx_jobs_user_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_jobs_user_id ON public.jobs USING btree (user_id);


--
-- Name: idx_location_analytics_user_location; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_location_analytics_user_location ON public.location_analytics USING btree (user_id, location_type, start_date);


--
-- Name: idx_personal_data_fields_table_column; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_personal_data_fields_table_column ON public.personal_data_fields USING btree (table_name, column_name);


--
-- Name: idx_privacy_control_labels_code; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_privacy_control_labels_code ON public.privacy_control_labels USING btree (label_code);


--
-- Name: idx_privacy_sensitivity_levels_code; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_privacy_sensitivity_levels_code ON public.privacy_sensitivity_levels USING btree (level_code);


--
-- Name: idx_processed_jobs_qualifications; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_jobs_qualifications ON public.processed_jobs USING gin (qualifications);


--
-- Name: idx_processed_resumes_experiences; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_resumes_experiences ON public.processed_resumes USING gin (experiences);


--
-- Name: idx_processed_resumes_skills; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_processed_resumes_skills ON public.processed_resumes USING gin (skills);


--
-- Name: idx_relationships_contact_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_relationships_contact_id ON public.relationships USING btree (contact_id);


--
-- Name: idx_relationships_type_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_relationships_type_id ON public.relationships USING btree (relationship_type_id);


--
-- Name: idx_relationships_user_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_relationships_user_id ON public.relationships USING btree (user_id);


--
-- Name: idx_resume_job_matches_scores; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_resume_job_matches_scores ON public.resume_job_matches USING btree (overall_score DESC, skill_match_score DESC);


--
-- Name: idx_tasks_contact_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_tasks_contact_id ON public.tasks USING btree (contact_id);


--
-- Name: idx_tasks_due_date; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_tasks_due_date ON public.tasks USING btree (due_date);


--
-- Name: idx_tasks_status; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_tasks_status ON public.tasks USING btree (status);


--
-- Name: idx_tasks_user_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_tasks_user_id ON public.tasks USING btree (user_id);


--
-- Name: idx_user_privacy_controls_user_field; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_user_privacy_controls_user_field ON public.user_privacy_controls USING btree (user_id, field_id);


--
-- Name: idx_user_privacy_preferences_user_field; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_user_privacy_preferences_user_field ON public.user_privacy_preferences USING btree (user_id, field_id);


--
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_work_experiences_company_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_work_experiences_company_id ON public.work_experiences USING btree (company_id);


--
-- Name: idx_work_experiences_dates; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_work_experiences_dates ON public.work_experiences USING btree (start_date, end_date);


--
-- Name: idx_work_experiences_location; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_work_experiences_location ON public.work_experiences USING btree (company_latitude, company_longitude);


--
-- Name: idx_work_experiences_user_id; Type: INDEX; Schema: public; Owner: szjason72
--

CREATE INDEX idx_work_experiences_user_id ON public.work_experiences USING btree (user_id);


--
-- Name: ai_embeddings update_ai_embeddings_updated_at; Type: TRIGGER; Schema: public; Owner: szjason72
--

CREATE TRIGGER update_ai_embeddings_updated_at BEFORE UPDATE ON public.ai_embeddings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: companies update_companies_updated_at; Type: TRIGGER; Schema: public; Owner: szjason72
--

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON public.companies FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: education update_education_updated_at; Type: TRIGGER; Schema: public; Owner: szjason72
--

CREATE TRIGGER update_education_updated_at BEFORE UPDATE ON public.education FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: jobs update_jobs_updated_at; Type: TRIGGER; Schema: public; Owner: szjason72
--

CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: work_experiences update_work_experiences_updated_at; Type: TRIGGER; Schema: public; Owner: szjason72
--

CREATE TRIGGER update_work_experiences_updated_at BEFORE UPDATE ON public.work_experiences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: activities activities_activity_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_activity_type_id_fkey FOREIGN KEY (activity_type_id) REFERENCES public.activity_types(id);


--
-- Name: activities activities_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: activities activities_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.activities
    ADD CONSTRAINT activities_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: addresses addresses_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: career_tracking career_tracking_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.career_tracking
    ADD CONSTRAINT career_tracking_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: career_trajectory career_trajectory_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.career_trajectory
    ADD CONSTRAINT career_trajectory_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: contact_information contact_information_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_information
    ADD CONSTRAINT contact_information_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: contact_information contact_information_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_information
    ADD CONSTRAINT contact_information_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.contact_information_types(id);


--
-- Name: contact_recommendations contact_recommendations_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_recommendations
    ADD CONSTRAINT contact_recommendations_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: contact_recommendations contact_recommendations_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_recommendations
    ADD CONSTRAINT contact_recommendations_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: contact_recommendations contact_recommendations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_recommendations
    ADD CONSTRAINT contact_recommendations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: contact_references contact_references_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_references
    ADD CONSTRAINT contact_references_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: contact_references contact_references_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contact_references
    ADD CONSTRAINT contact_references_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: contacts contacts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: data_access_logs data_access_logs_accessed_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.data_access_logs
    ADD CONSTRAINT data_access_logs_accessed_user_id_fkey FOREIGN KEY (accessed_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: data_access_logs data_access_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.data_access_logs
    ADD CONSTRAINT data_access_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: data_masking_rules data_masking_rules_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.data_masking_rules
    ADD CONSTRAINT data_masking_rules_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.personal_data_fields(id);


--
-- Name: education education_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.education
    ADD CONSTRAINT education_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: field_privacy_controls field_privacy_controls_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.field_privacy_controls
    ADD CONSTRAINT field_privacy_controls_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.personal_data_fields(id);


--
-- Name: field_privacy_controls field_privacy_controls_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.field_privacy_controls
    ADD CONSTRAINT field_privacy_controls_label_id_fkey FOREIGN KEY (label_id) REFERENCES public.privacy_control_labels(id);


--
-- Name: files files_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: job_applications job_applications_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_applications
    ADD CONSTRAINT job_applications_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: job_applications job_applications_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_applications
    ADD CONSTRAINT job_applications_resume_id_fkey FOREIGN KEY (resume_id) REFERENCES public.resumes(id) ON DELETE CASCADE;


--
-- Name: job_applications job_applications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_applications
    ADD CONSTRAINT job_applications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: job_embeddings job_embeddings_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_embeddings
    ADD CONSTRAINT job_embeddings_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: job_matches job_matches_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_matches
    ADD CONSTRAINT job_matches_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: job_matches job_matches_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.job_matches
    ADD CONSTRAINT job_matches_resume_id_fkey FOREIGN KEY (resume_id) REFERENCES public.resumes(id) ON DELETE CASCADE;


--
-- Name: jobs jobs_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: jobs jobs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: location_analytics location_analytics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.location_analytics
    ADD CONSTRAINT location_analytics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: network_analytics network_analytics_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.network_analytics
    ADD CONSTRAINT network_analytics_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: notes notes_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: notes notes_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE SET NULL;


--
-- Name: notes notes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: personal_data_fields personal_data_fields_sensitivity_level_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.personal_data_fields
    ADD CONSTRAINT personal_data_fields_sensitivity_level_id_fkey FOREIGN KEY (sensitivity_level_id) REFERENCES public.privacy_sensitivity_levels(id);


--
-- Name: processed_jobs processed_jobs_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.processed_jobs
    ADD CONSTRAINT processed_jobs_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: processed_resumes processed_resumes_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.processed_resumes
    ADD CONSTRAINT processed_resumes_resume_id_fkey FOREIGN KEY (resume_id) REFERENCES public.resumes(id) ON DELETE CASCADE;


--
-- Name: projects projects_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: relationships relationships_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE CASCADE;


--
-- Name: relationships relationships_relationship_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_relationship_type_id_fkey FOREIGN KEY (relationship_type_id) REFERENCES public.relationship_types(id);


--
-- Name: relationships relationships_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.relationships
    ADD CONSTRAINT relationships_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reminders reminders_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.reminders
    ADD CONSTRAINT reminders_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: reminders reminders_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.reminders
    ADD CONSTRAINT reminders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: resume_embeddings resume_embeddings_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resume_embeddings
    ADD CONSTRAINT resume_embeddings_resume_id_fkey FOREIGN KEY (resume_id) REFERENCES public.resumes(id) ON DELETE CASCADE;


--
-- Name: resume_job_matches resume_job_matches_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resume_job_matches
    ADD CONSTRAINT resume_job_matches_job_id_fkey FOREIGN KEY (job_id) REFERENCES public.jobs(id) ON DELETE CASCADE;


--
-- Name: resume_job_matches resume_job_matches_resume_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resume_job_matches
    ADD CONSTRAINT resume_job_matches_resume_id_fkey FOREIGN KEY (resume_id) REFERENCES public.resumes(id) ON DELETE CASCADE;


--
-- Name: resumes resumes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.resumes
    ADD CONSTRAINT resumes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: skill_embeddings skill_embeddings_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.skill_embeddings
    ADD CONSTRAINT skill_embeddings_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;


--
-- Name: tasks tasks_contact_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_contact_id_fkey FOREIGN KEY (contact_id) REFERENCES public.contacts(id) ON DELETE SET NULL;


--
-- Name: tasks tasks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.tasks
    ADD CONSTRAINT tasks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_privacy_controls user_privacy_controls_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_controls
    ADD CONSTRAINT user_privacy_controls_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.personal_data_fields(id);


--
-- Name: user_privacy_controls user_privacy_controls_label_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_controls
    ADD CONSTRAINT user_privacy_controls_label_id_fkey FOREIGN KEY (label_id) REFERENCES public.privacy_control_labels(id);


--
-- Name: user_privacy_controls user_privacy_controls_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_controls
    ADD CONSTRAINT user_privacy_controls_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_privacy_preferences user_privacy_preferences_field_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_preferences
    ADD CONSTRAINT user_privacy_preferences_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.personal_data_fields(id);


--
-- Name: user_privacy_preferences user_privacy_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_privacy_preferences
    ADD CONSTRAINT user_privacy_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_profiles user_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_skills user_skills_skill_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT user_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.skills(id) ON DELETE CASCADE;


--
-- Name: user_skills user_skills_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.user_skills
    ADD CONSTRAINT user_skills_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: work_experiences work_experiences_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.work_experiences
    ADD CONSTRAINT work_experiences_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;


--
-- Name: work_experiences work_experiences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: szjason72
--

ALTER TABLE ONLY public.work_experiences
    ADD CONSTRAINT work_experiences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict Xc0MJ3ijXcEjpasNsG9e3S6ZElt8UsrPCqJvVeg6jP9hsIQbB0qiCAJaV3ZPo4O

