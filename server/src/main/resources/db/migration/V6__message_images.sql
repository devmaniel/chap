-- Which phone photos belong to which message. The photo itself never leaves
-- the phone: device_ref is the app's local file path, not image data.
CREATE TABLE message_images (
    message_id UUID NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
    position   SMALLINT NOT NULL CHECK (position BETWEEN 0 AND 3),
    device_ref TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (message_id, position)
);

CREATE TRIGGER message_images_set_updated_at BEFORE UPDATE ON message_images
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
