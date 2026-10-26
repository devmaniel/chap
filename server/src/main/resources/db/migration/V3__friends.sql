-- The built-in AI characters. Reference data: rows come from migrations only.
CREATE TABLE characters (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- The id the app and API use, e.g. "mina".
    slug                TEXT NOT NULL UNIQUE,
    name                TEXT NOT NULL,
    tagline             TEXT NOT NULL,
    bio                 TEXT NOT NULL,
    home                TEXT NOT NULL,
    -- How they sound, shown on the profile, e.g. "Warm & gentle".
    voice_label         TEXT NOT NULL,
    first_hello         TEXT NOT NULL,
    -- The AI's character brief. Never sent to the app as profile data.
    persona             TEXT NOT NULL,
    interests           TEXT[] NOT NULL,
    -- Filled by a later migration once voices are picked.
    elevenlabs_voice_id TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER characters_set_updated_at BEFORE UPDATE ON characters
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Which characters each user has added as friends.
CREATE TABLE user_friends (
    user_id      UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES characters (id) ON DELETE RESTRICT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, character_id)
);

CREATE INDEX user_friends_character_id_idx ON user_friends (character_id);

CREATE TRIGGER user_friends_set_updated_at BEFORE UPDATE ON user_friends
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
