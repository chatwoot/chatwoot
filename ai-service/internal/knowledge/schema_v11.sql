-- Schema version 11: data feeds next to website pages (additive). A source is
-- either one web page ('page', as in v9) or a CSV / JSON Lines file whose rows
-- each become a document keyed 'feed:<source id>:<row id>' ('feed').
-- checking_until marks a source as being checked (a lease), so "Sync now"
-- cannot start a second check of the same source.
SET LOCAL lock_timeout = '5s';

ALTER TABLE web_sources ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT 'page';
ALTER TABLE web_sources DROP CONSTRAINT IF EXISTS web_sources_kind_check;
ALTER TABLE web_sources ADD CONSTRAINT web_sources_kind_check CHECK (kind IN ('page', 'feed'));
ALTER TABLE web_sources ADD COLUMN IF NOT EXISTS item_count INT NOT NULL DEFAULT 0;
ALTER TABLE web_sources DROP CONSTRAINT IF EXISTS web_sources_item_count_check;
ALTER TABLE web_sources ADD CONSTRAINT web_sources_item_count_check CHECK (item_count BETWEEN 0 AND 100000);
ALTER TABLE web_sources ADD COLUMN IF NOT EXISTS checking_until TIMESTAMPTZ;
