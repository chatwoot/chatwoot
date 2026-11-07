-- Staging only (DEV-Johnstocker/chatwoot#37): ai-service keeps its knowledge
-- base in its own database next to Chatwoot's. Runs once, on an empty volume.
CREATE DATABASE ai_service;
