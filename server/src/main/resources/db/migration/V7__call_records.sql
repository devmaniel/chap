-- Set only on a call record: the message saying you called, and for how long.
-- Its body is empty.
ALTER TABLE messages
    ADD COLUMN call_duration_seconds INTEGER CHECK (call_duration_seconds >= 0);
