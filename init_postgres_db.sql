CREATE TABLE comments (
    id serial primary key,
    post_id integer DEFAULT 0,
    text text DEFAULT '',
    name text DEFAULT '',
    "time" timestamp without time zone DEFAULT now(),
    t integer DEFAULT date_part('epoch'::text, now())
);


CREATE TABLE posts (
    id serial primary key,
    text text DEFAULT ''::text,
    title text DEFAULT ''::text,
    "time" timestamp without time zone DEFAULT now(),
    nr_comments integer DEFAULT 0,
    is_blog boolean DEFAULT false,
    last_reply timestamp without time zone DEFAULT now(),
    is_deleted boolean DEFAULT false,
    is_locked bool default false
);


CREATE TABLE users (
    id serial primary key,
    name text DEFAULT ''::text,
    random_id text DEFAULT ''::text,
    is_banned bool default false,
    is_admin bool default false

);

