-- CUSTOMIZAÇÃO_SYNAPSEOS — Reset zero-state pré nova rodada de testes
-- Roda contra o DB chatwoot. Preserva: contacts, inboxes, accounts, users,
-- agents, agent_bots, synapseos_pipeline_stages (config), templates,
-- inbox_members. Apaga: conversas (+ msgs, attachments, etc.) e estado
-- Synapseos CRM (leads/deals/eventos).

\echo '==> Wipe chatwoot DB iniciando'

BEGIN;

-- Conversas + tudo que tem FK pra conversations (mensagens, anexos,
-- participants, mentions, notifications, csat, copilot, etc.).
TRUNCATE TABLE conversations RESTART IDENTITY CASCADE;

-- Eventos de reporting (não cascateiam de conversations em todas as versões)
TRUNCATE TABLE reporting_events RESTART IDENTITY CASCADE;
TRUNCATE TABLE reporting_events_rollups RESTART IDENTITY CASCADE;

-- Estado do CRM Synapseos. Preserva synapseos_pipeline_stages (config).
TRUNCATE TABLE
  synapseos_crm_events,
  synapseos_deals,
  synapseos_leads
RESTART IDENTITY CASCADE;

-- Sanidade: confirmar contagens zeradas e configs preservadas
\echo ''
\echo '==> Sanity check (deve mostrar zero pra conversas/leads e >0 pra configs)'
SELECT 'conversations' AS table, COUNT(*) FROM conversations
UNION ALL SELECT 'messages', COUNT(*) FROM messages
UNION ALL SELECT 'synapseos_leads', COUNT(*) FROM synapseos_leads
UNION ALL SELECT 'synapseos_deals', COUNT(*) FROM synapseos_deals
UNION ALL SELECT 'synapseos_crm_events', COUNT(*) FROM synapseos_crm_events
UNION ALL SELECT 'contacts (preservar)', COUNT(*) FROM contacts
UNION ALL SELECT 'inboxes (preservar)', COUNT(*) FROM inboxes
UNION ALL SELECT 'synapseos_pipeline_stages (preservar)', COUNT(*) FROM synapseos_pipeline_stages;

COMMIT;

\echo ''
\echo '==> Wipe chatwoot OK. Rode wipe_synapseos_audi.sql contra o DB synapseos_audi.'
