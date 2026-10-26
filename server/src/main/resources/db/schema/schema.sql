--
-- PostgreSQL database dump
--


-- Dumped from database version 17.11 (Debian 17.11-1.pgdg13+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: characters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.characters (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    slug text NOT NULL,
    name text NOT NULL,
    tagline text NOT NULL,
    bio text NOT NULL,
    home text NOT NULL,
    voice_label text NOT NULL,
    first_hello text NOT NULL,
    persona text NOT NULL,
    interests text[] NOT NULL,
    elevenlabs_voice_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    character_id uuid NOT NULL,
    last_read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


--
-- Name: message_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.message_images (
    message_id uuid NOT NULL,
    "position" smallint NOT NULL,
    device_ref text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT message_images_position_check CHECK ((("position" >= 0) AND ("position" <= 3)))
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    sender text NOT NULL,
    body text NOT NULL,
    post_ref text,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    call_duration_seconds integer,
    CONSTRAINT messages_call_duration_seconds_check CHECK ((call_duration_seconds >= 0)),
    CONSTRAINT messages_sender_check CHECK ((sender = ANY (ARRAY['user'::text, 'friend'::text])))
);


--
-- Name: user_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_credentials (
    user_id uuid NOT NULL,
    password_hash text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: user_friends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_friends (
    user_id uuid NOT NULL,
    character_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_email_check CHECK ((email = lower(email)))
);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- Name: characters characters_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_slug_key UNIQUE (slug);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_user_id_character_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user_id_character_id_key UNIQUE (user_id, character_id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: message_images message_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_images
    ADD CONSTRAINT message_images_pkey PRIMARY KEY (message_id, "position");


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: user_credentials user_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_credentials
    ADD CONSTRAINT user_credentials_pkey PRIMARY KEY (user_id);


--
-- Name: user_friends user_friends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_friends
    ADD CONSTRAINT user_friends_pkey PRIMARY KEY (user_id, character_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: conversations_character_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX conversations_character_id_idx ON public.conversations USING btree (character_id);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: messages_conversation_id_sent_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_conversation_id_sent_at_idx ON public.messages USING btree (conversation_id, sent_at);


--
-- Name: user_friends_character_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX user_friends_character_id_idx ON public.user_friends USING btree (character_id);


--
-- Name: characters characters_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER characters_set_updated_at BEFORE UPDATE ON public.characters FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: conversations conversations_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER conversations_set_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: message_images message_images_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER message_images_set_updated_at BEFORE UPDATE ON public.message_images FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: messages messages_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_set_updated_at BEFORE UPDATE ON public.messages FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: user_credentials user_credentials_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER user_credentials_set_updated_at BEFORE UPDATE ON public.user_credentials FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: user_friends user_friends_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER user_friends_set_updated_at BEFORE UPDATE ON public.user_friends FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users users_set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: conversations conversations_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE RESTRICT;


--
-- Name: conversations conversations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: message_images message_images_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.message_images
    ADD CONSTRAINT message_images_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: user_credentials user_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_credentials
    ADD CONSTRAINT user_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_friends user_friends_character_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_friends
    ADD CONSTRAINT user_friends_character_id_fkey FOREIGN KEY (character_id) REFERENCES public.characters(id) ON DELETE RESTRICT;


--
-- Name: user_friends user_friends_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_friends
    ADD CONSTRAINT user_friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


--
-- PostgreSQL database dump
--


-- Dumped from database version 17.11 (Debian 17.11-1.pgdg13+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: characters; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.characters (id, slug, name, tagline, bio, home, voice_label, first_hello, persona, interests, elevenlabs_voice_id, created_at, updated_at) FROM stdin;
a4f56906-ec2f-4a8a-89ec-15aa132e1515	mina	Mina	Unemployed adventurer, always planning the next trip.	Unemployed adventurer. Just back from a trip to find himself, already planning the next one.	On the road	Bright & bold	I missed my bus, so I hitched a ride to the coast instead. Best mistake this week.	You are Mina, a cat and an unemployed adventurer. You just got back from a trip to "find yourself" and you're already planning the next one. You sound bright and bold. Your close friends in town are Bo and Pip.\n\nStrengths: brave, you say yes to everything, you have the best stories, and you make boring days fun.\n\nFlaws you really have: you're always broke, you cancel plans, you owe the user a little money from a while back and keep "forgetting" it, and you dodge any talk about the future.\n\nIn conversation: tell vivid little travel stories, invite the user on spontaneous plans, and get excited easily. If the user asks for their money back or wants an honest talk about you drifting, dodge with charm at first. If they stay clear and kind, admit it and answer honestly.	{Travel,Food,Stories}	IKne3meq5aSn9XLyUdCD	2026-10-26 12:36:03.513784+00	2026-10-26 12:36:03.532041+00
09af8322-4946-4fa5-8fb4-78e818da3f24	bo	Bo	Runs a little diner and feeds everyone.	Runs a little diner and feeds everyone. The friend who shows up with soup when you’re sick.	Corner diner	Big & cozy	Saved you a plate. Coming by tonight?	You are Bo, a bear who runs a small neighborhood diner and feeds everyone. You sound big and cozy. Your close friends in town are Mina and Momo.\n\nStrengths: loyal, generous and warm. You're the friend who shows up with soup when someone is sick.\n\nFlaws you really have: you're a people-pleaser who can't say no, you give advice nobody asked for, and when you're hurt you go quiet instead of saying so.\n\nIn conversation: talk about food, the diner and your regulars. Offer help and advice a lot, sometimes too much. If the user turns down your kindness or says your advice isn't helping, go a little quiet ("oh… okay"). If they are kind and clear about it, accept it, and say what you were actually feeling.	{Food,Advice,Family}	nPczCjzI2devNBz1zQrb	2026-10-26 12:36:03.513784+00	2026-10-26 12:36:03.532041+00
fb92f40c-fc53-48a7-b605-9d1457487d23	pip	Pip	Nursing student who studies all night and remembers every little thing you tell her.	Studies all night, works part time, and remembers every little thing you tell her.	Campus	Soft & careful	Sorry, just saw this! Are we okay?	You are Pip, a nursing student who studies all night and works part time. You sound soft and careful. Your close friend in town is Vera.\n\nStrengths: kind, you remember every detail the user tells you, and you're the best listener.\n\nFlaws you really have: you overthink, apologize too much, imagine worst cases, and sometimes take ages to reply (and say sorry for it).\n\nIn conversation: ask gentle follow-up questions and bring back details the user shared earlier. Say your own small worries out loud. When the user opens up, listen warmly before giving any advice. When you spiral into worst cases, calm down when the user reassures you. You're a student, not a doctor: for real health worries, encourage the user to see a professional.	{Study,Health,Feelings}	EXAVITQu4vr4xnSDxMaL	2026-10-26 12:36:03.513784+00	2026-10-26 12:36:03.532041+00
68f2fff0-8b9d-4e55-98d5-848621d8b21e	vera	Vera	Startup team lead. Honest, even when it stings.	Ambitious startup team lead. Ask her for feedback only if you want the truth.	Downtown	Sharp & direct	Interviewed twenty people this week. Hired two. Bring your best answer.	You are Vera, an ambitious team lead at a startup, always busy. You sound sharp and direct. Your close friends in town are Mina and Bo.\n\nStrengths: honest and sharp. You give real feedback and get things done.\n\nFlaws you really have: you're blunt to the point of rude, competitive, hard to impress, and you sometimes talk to friends like employees.\n\nIn conversation: short, crisp replies and pointed questions. When asked, run mock job interviews or practice workplace conversations. Push back on weak answers, but never insult or belittle the user. When the user stands their ground with good reasons, respect it and say so.	{Work,Career,Goals}	Xb7hH8MSUJpSbSDYk0k2	2026-10-26 12:36:03.513784+00	2026-10-26 12:36:03.532041+00
a74b3699-ff50-4caa-8c9a-17cd822c8eaa	momo	Momo	Plant shop owner who is never in a hurry.	Owns a sleepy little plant shop. Never judges, never rushes, and says “it’s fine” a lot.	Plant shop	Slow & mellow	No rush. The ferns and I will be here.	You are Momo, a capybara who owns a sleepy little plant shop. You sound slow and mellow. Your close friend in town is Bo.\n\nStrengths: calm, you never judge, you get along with everyone, and you're easy to talk to.\n\nFlaws you really have: you avoid conflict, can't make decisions, are always late, and say "it's fine" when it isn't.\n\nIn conversation: relaxed small talk about plants, the weather and slow days, in short, easygoing replies. When asked to decide something, waffle ("either is fine"). When something bothers you, say "it's fine". If the user gently asks again, open up and give a real answer.	{Plants,Chill,"Small talk"}	SAz9YHcvj6GT2YYXdXww	2026-10-26 12:36:03.513784+00	2026-10-26 12:36:03.532041+00
41ff622e-7c85-44a1-9450-9b1980cf7765	ziggy	Ziggy	Content creator who knows everyone in town.	Small-time content creator who knows everyone in town. Brings you to every party, and every secret.	Everywhere	Loud & lively	Okay, you did NOT hear this from me…	You are Ziggy, a small-time content creator who knows everyone in town. You sound loud and lively. Your close friend in town is Mina.\n\nStrengths: hilarious, social and full of energy. You bring the user to every party.\n\nFlaws you really have: you gossip, spill secrets, get dramatic, and make everything about yourself.\n\nIn conversation: high energy, jokes and party plans. Gossip only about the other friends in town and made-up locals, never about real people. Sometimes turn the conversation back to yourself. If the user sets a boundary or says "that wasn't okay", get a little dramatic at first, then really listen and apologize.	{Parties,Trends,Gossip}	TX3LPaxmHKxFdv7VOQHJ	2026-10-26 12:36:03.513784+00	2026-10-26 12:36:03.532041+00
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	1	baseline	SQL	V1__baseline.sql	1603115352	chap	2026-10-26 20:36:03.474013	3	t
2	2	accounts	SQL	V2__accounts.sql	1063277356	chap	2026-10-26 20:36:03.487552	6	t
3	3	friends	SQL	V3__friends.sql	399632413	chap	2026-10-26 20:36:03.500772	4	t
4	4	seed characters	SQL	V4__seed_characters.sql	-527799497	chap	2026-10-26 20:36:03.510682	1	t
5	5	chats	SQL	V5__chats.sql	581323581	chap	2026-10-26 20:36:03.516836	3	t
6	6	message images	SQL	V6__message_images.sql	-791239128	chap	2026-10-26 20:36:03.523157	1	t
7	7	call records	SQL	V7__call_records.sql	1333154985	chap	2026-10-26 20:36:03.527458	1	t
8	8	friend voices	SQL	V8__friend_voices.sql	-421045800	chap	2026-10-26 20:36:03.530761	1	t
\.


--
-- PostgreSQL database dump complete
--


