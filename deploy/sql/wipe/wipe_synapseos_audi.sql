-- CUSTOMIZAÇÃO_SYNAPSEOS — Reset estado operacional dos workflows n8n da
-- Audi. Roda contra o DB synapseos_audi. Preserva agent_rag_prompts (config
-- dos prompts curados manualmente).

\echo '==> Wipe synapseos_audi DB iniciando'

BEGIN;

TRUNCATE TABLE
  leads,
  buffer_message,
  n8n_chat_histories,
  intervencao_humana,
  memoria,
  logs_alertas_enviados,
  followup_schedule,
  "FollowUp_Control",
  curadoria_interacao_ai
RESTART IDENTITY CASCADE;

\echo ''
\echo '==> Sanity check'
SELECT 'leads' AS table, COUNT(*) FROM leads
UNION ALL SELECT 'buffer_message', COUNT(*) FROM buffer_message
UNION ALL SELECT 'n8n_chat_histories', COUNT(*) FROM n8n_chat_histories
UNION ALL SELECT 'intervencao_humana', COUNT(*) FROM intervencao_humana
UNION ALL SELECT 'memoria', COUNT(*) FROM memoria
UNION ALL SELECT 'logs_alertas_enviados', COUNT(*) FROM logs_alertas_enviados
UNION ALL SELECT 'followup_schedule', COUNT(*) FROM followup_schedule
UNION ALL SELECT 'FollowUp_Control', COUNT(*) FROM "FollowUp_Control"
UNION ALL SELECT 'curadoria_interacao_ai', COUNT(*) FROM curadoria_interacao_ai
UNION ALL SELECT 'agent_rag_prompts (preservar)', COUNT(*) FROM agent_rag_prompts;

COMMIT;

\echo ''
\echo '==> Wipe synapseos_audi OK.'
