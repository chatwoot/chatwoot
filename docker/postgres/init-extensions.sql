-- PostgreSQL Extensions for Chatwoot
-- These extensions are automatically loaded when the database is first created

-- UUID generation (required for Chatwoot)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Cryptographic functions (required for Chatwoot)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Performance monitoring (optional but recommended for development)
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Full-text search enhancements (useful for conversation search)
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- Trigram matching for fuzzy search (useful for contact search)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Show loaded extensions
SELECT extname, extversion FROM pg_extension ORDER BY extname;
