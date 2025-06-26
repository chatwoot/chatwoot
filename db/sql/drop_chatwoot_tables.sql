-- SQL Script to drop Chatwoot tables

DROP TABLE IF EXISTS "access_tokens" CASCADE;
DROP TABLE IF EXISTS "account_users" CASCADE;
DROP TABLE IF EXISTS "accounts" CASCADE;
DROP TABLE IF EXISTS "action_mailbox_inbound_emails" CASCADE;
DROP TABLE IF EXISTS "active_storage_attachments" CASCADE;
DROP TABLE IF EXISTS "active_storage_blobs" CASCADE;
DROP TABLE IF EXISTS "active_storage_variant_records" CASCADE;
DROP TABLE IF EXISTS "agent_bot_inboxes" CASCADE;
DROP TABLE IF EXISTS "agent_bots" CASCADE;
DROP TABLE IF EXISTS "applied_slas" CASCADE;
DROP TABLE IF EXISTS "article_embeddings" CASCADE;
DROP TABLE IF EXISTS "articles" CASCADE;
DROP TABLE IF EXISTS "attachments" CASCADE;
DROP TABLE IF EXISTS "audits" CASCADE;
DROP TABLE IF EXISTS "automation_rules" CASCADE;
DROP TABLE IF EXISTS "campaigns" CASCADE;
DROP TABLE IF EXISTS "canned_responses" CASCADE;
DROP TABLE IF EXISTS "captain_assistant_responses" CASCADE;
DROP TABLE IF EXISTS "captain_assistants" CASCADE;
DROP TABLE IF EXISTS "captain_documents" CASCADE;
DROP TABLE IF EXISTS "captain_inboxes" CASCADE;
DROP TABLE IF EXISTS "categories" CASCADE;
DROP TABLE IF EXISTS "channel_api" CASCADE;
DROP TABLE IF EXISTS "channel_email" CASCADE;
DROP TABLE IF EXISTS "channel_facebook_pages" CASCADE;
DROP TABLE IF EXISTS "channel_instagram" CASCADE;
DROP TABLE IF EXISTS "channel_line" CASCADE;
DROP TABLE IF EXISTS "channel_sms" CASCADE;
DROP TABLE IF EXISTS "channel_telegram" CASCADE;
DROP TABLE IF EXISTS "channel_twilio_sms" CASCADE;
DROP TABLE IF EXISTS "channel_twitter_profiles" CASCADE;
DROP TABLE IF EXISTS "channel_web_widgets" CASCADE;
DROP TABLE IF EXISTS "channel_whatsapp" CASCADE;
DROP TABLE IF EXISTS "contact_inboxes" CASCADE;
DROP TABLE IF EXISTS "contacts" CASCADE;
DROP TABLE IF EXISTS "conversation_participants" CASCADE;
DROP TABLE IF EXISTS "conversations" CASCADE;
DROP TABLE IF EXISTS "csat_survey_responses" CASCADE;
DROP TABLE IF EXISTS "custom_attribute_definitions" CASCADE;
DROP TABLE IF EXISTS "custom_filters" CASCADE;
DROP TABLE IF EXISTS "custom_roles" CASCADE;
DROP TABLE IF EXISTS "dashboard_apps" CASCADE;
DROP TABLE IF EXISTS "data_imports" CASCADE;
DROP TABLE IF EXISTS "email_templates" CASCADE;
DROP TABLE IF EXISTS "folders" CASCADE;
DROP TABLE IF EXISTS "inbox_members" CASCADE;
DROP TABLE IF EXISTS "inboxes" CASCADE;
DROP TABLE IF EXISTS "installation_configs" CASCADE;
DROP TABLE IF EXISTS "integrations_hooks" CASCADE;
DROP TABLE IF EXISTS "labels" CASCADE;
DROP TABLE IF EXISTS "macros" CASCADE;
DROP TABLE IF EXISTS "mentions" CASCADE;
DROP TABLE IF EXISTS "messages" CASCADE;
DROP TABLE IF EXISTS "notes" CASCADE;
DROP TABLE IF EXISTS "notification_settings" CASCADE;
DROP TABLE IF EXISTS "notification_subscriptions" CASCADE;
DROP TABLE IF EXISTS "notifications" CASCADE;
DROP TABLE IF EXISTS "platform_app_permissibles" CASCADE;
DROP TABLE IF EXISTS "platform_apps" CASCADE;
DROP TABLE IF EXISTS "portal_members" CASCADE;
DROP TABLE IF EXISTS "portals" CASCADE;
DROP TABLE IF EXISTS "portals_members" CASCADE;
DROP TABLE IF EXISTS "related_categories" CASCADE;
DROP TABLE IF EXISTS "reporting_events" CASCADE;
DROP TABLE IF EXISTS "schema_migrations" CASCADE; -- Standard Rails table
DROP TABLE IF EXISTS "ar_internal_metadata" CASCADE; -- Standard Rails table
DROP TABLE IF EXISTS "sla_events" CASCADE;
DROP TABLE IF EXISTS "sla_policies" CASCADE;
DROP TABLE IF EXISTS "taggings" CASCADE;
DROP TABLE IF EXISTS "tags" CASCADE;
DROP TABLE IF EXISTS "team_members" CASCADE;
DROP TABLE IF EXISTS "teams" CASCADE;
DROP TABLE IF EXISTS "telegram_bots" CASCADE;
DROP TABLE IF EXISTS "users" CASCADE;
DROP TABLE IF EXISTS "webhooks" CASCADE;
DROP TABLE IF EXISTS "working_hours" CASCADE;
DROP TABLE IF EXISTS "account_prompts" CASCADE;

-- Sequences created by triggers might need to be dropped manually if they persist.
-- Example: DROP SEQUENCE IF EXISTS conv_dpid_seq_X CASCADE;
-- Example: DROP SEQUENCE IF EXISTS camp_dpid_seq_X CASCADE;
-- Replace X with the account ID. You might need to list sequences in your DB to find all of them.

-- Note: pgcrypto, pg_stat_statements, pg_trgm, plpgsql, and vector extensions are not dropped by this script. 