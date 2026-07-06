# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_07_06_000001) do
  # These extensions should be enabled to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "access_tokens", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_access_tokens_on_owner_type_and_owner_id"
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
  end

  create_table "account_email_oauth_apps", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "provider", null: false
    t.text "client_id"
    t.text "client_secret"
    t.string "redirect_uri"
    t.jsonb "settings", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "provider"], name: "index_account_email_oauth_apps_on_account_id_and_provider", unique: true
  end

  create_table "account_saml_settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "sso_url"
    t.text "certificate"
    t.string "sp_entity_id"
    t.string "idp_entity_id"
    t.json "role_mappings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_saml_settings_on_account_id"
  end

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "user_id"
    t.integer "role", default: 0
    t.bigint "inviter_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "active_at", precision: nil
    t.integer "availability", default: 0, null: false
    t.boolean "auto_offline", default: true, null: false
    t.bigint "custom_role_id"
    t.bigint "agent_capacity_policy_id"
    t.boolean "integration", default: false, null: false
    t.index ["account_id", "user_id"], name: "uniq_user_id_per_account_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["agent_capacity_policy_id"], name: "index_account_users_on_agent_capacity_policy_id"
    t.index ["custom_role_id"], name: "index_account_users_on_custom_role_id"
    t.index ["integration"], name: "index_account_users_on_integration"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "locale", default: 0
    t.string "domain", limit: 100
    t.string "support_email", limit: 100
    t.bigint "feature_flags", default: 0, null: false
    t.integer "auto_resolve_duration"
    t.jsonb "limits", default: {}
    t.jsonb "custom_attributes", default: {}
    t.integer "status", default: 0
    t.jsonb "internal_attributes", default: {}, null: false
    t.jsonb "settings", default: {}
    t.bigint "flags", default: 0, null: false
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agent_bot_inboxes", force: :cascade do |t|
    t.integer "inbox_id"
    t.integer "agent_bot_id"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
  end

  create_table "agent_bots", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "outgoing_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.integer "bot_type", default: 0
    t.jsonb "bot_config", default: {}
    t.string "secret"
    t.index ["account_id"], name: "index_agent_bots_on_account_id"
  end

  create_table "agent_capacity_policies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.jsonb "exclusion_rules", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_agent_capacity_policies_on_account_id"
  end

  create_table "applied_slas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "sla_policy_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sla_status", default: 0
    t.jsonb "metadata", default: {}, null: false
    t.index ["account_id", "sla_policy_id", "conversation_id"], name: "index_applied_slas_on_account_sla_policy_conversation", unique: true
    t.index ["account_id"], name: "index_applied_slas_on_account_id"
    t.index ["conversation_id"], name: "index_applied_slas_on_conversation_id"
    t.index ["sla_policy_id"], name: "index_applied_slas_on_sla_policy_id"
  end

  create_table "article_embeddings", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.text "term", null: false
    t.vector "embedding", limit: 1536
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["embedding"], name: "index_article_embeddings_on_embedding", using: :ivfflat
  end

  create_table "articles", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "portal_id", null: false
    t.integer "category_id"
    t.integer "folder_id"
    t.string "title"
    t.text "description"
    t.text "content"
    t.integer "status"
    t.integer "views"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "author_id"
    t.bigint "associated_article_id"
    t.jsonb "meta", default: {}
    t.string "slug", null: false
    t.integer "position"
    t.string "locale", default: "en", null: false
    t.index ["account_id"], name: "index_articles_on_account_id"
    t.index ["associated_article_id"], name: "index_articles_on_associated_article_id"
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["portal_id"], name: "index_articles_on_portal_id"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status"], name: "index_articles_on_status"
    t.index ["views"], name: "index_articles_on_views"
  end

  create_table "assignment_policies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.integer "assignment_order", default: 0, null: false
    t.integer "conversation_priority", default: 0, null: false
    t.integer "fair_distribution_limit", default: 100, null: false
    t.integer "fair_distribution_window", default: 3600, null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_assignment_policies_on_account_id_and_name", unique: true
    t.index ["account_id"], name: "index_assignment_policies_on_account_id"
    t.index ["enabled"], name: "index_assignment_policies_on_enabled"
  end

  create_table "attachments", id: :serial, force: :cascade do |t|
    t.integer "file_type", default: 0
    t.string "external_url"
    t.float "coordinates_lat", default: 0.0
    t.float "coordinates_long", default: 0.0
    t.integer "message_id", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "fallback_title"
    t.string "extension"
    t.jsonb "meta", default: {}
    t.index ["account_id"], name: "index_attachments_on_account_id"
    t.index ["message_id"], name: "index_attachments_on_message_id"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "auditable_id"
    t.string "auditable_type"
    t.bigint "associated_id"
    t.string "associated_type"
    t.bigint "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at", precision: nil
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "automation_rules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "event_name", null: false
    t.jsonb "conditions", default: "{}", null: false
    t.jsonb "actions", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["account_id"], name: "index_automation_rules_on_account_id"
  end

  create_table "autonomia_agent_build_threads", force: :cascade do |t|
    t.bigint "autonomia_agent_id"
    t.bigint "account_id", null: false
    t.jsonb "messages", default: [], null: false
    t.jsonb "state", default: {}, null: false
    t.string "build_token"
    t.integer "status", default: 0, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_autonomia_agent_build_threads_on_account_id_and_status"
    t.index ["account_id"], name: "index_autonomia_agent_build_threads_on_account_id"
    t.index ["autonomia_agent_id"], name: "index_autonomia_agent_build_threads_on_autonomia_agent_id"
    t.index ["created_by_id"], name: "index_autonomia_agent_build_threads_on_created_by_id"
  end

  create_table "autonomia_agent_events", force: :cascade do |t|
    t.bigint "autonomia_agent_id", null: false
    t.bigint "account_id", null: false
    t.bigint "conversation_id"
    t.integer "event_type", null: false
    t.float "confidence"
    t.boolean "answered_from_knowledge", default: false, null: false
    t.string "handoff_reason"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["account_id"], name: "index_autonomia_agent_events_on_account_id"
    t.index ["autonomia_agent_id", "created_at"], name: "idx_autonomia_events_agent_created"
    t.index ["autonomia_agent_id", "event_type"], name: "idx_autonomia_events_agent_type"
    t.index ["autonomia_agent_id"], name: "index_autonomia_agent_events_on_autonomia_agent_id"
  end

  create_table "autonomia_agent_inboxes", force: :cascade do |t|
    t.bigint "autonomia_agent_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "account_id", null: false
    t.bigint "agent_bot_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_autonomia_agent_inboxes_on_account_id"
    t.index ["agent_bot_id"], name: "index_autonomia_agent_inboxes_on_agent_bot_id"
    t.index ["autonomia_agent_id"], name: "index_autonomia_agent_inboxes_on_autonomia_agent_id"
    t.index ["inbox_id"], name: "idx_autonomia_agent_inboxes_on_inbox_uniq", unique: true
  end

  create_table "autonomia_agent_instruction_versions", force: :cascade do |t|
    t.bigint "autonomia_agent_id", null: false
    t.bigint "account_id", null: false
    t.text "instruction", null: false
    t.string "instruction_hash", null: false
    t.string "reason", null: false
    t.bigint "created_by_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "idx_autonomia_instruction_versions_on_account_id"
    t.index ["autonomia_agent_id", "created_at"], name: "idx_autonomia_instruction_versions_agent_created"
    t.index ["autonomia_agent_id"], name: "idx_autonomia_instruction_versions_on_agent_id"
    t.index ["created_by_id"], name: "idx_autonomia_instruction_versions_on_created_by"
  end

  create_table "autonomia_agent_knowledge", force: :cascade do |t|
    t.bigint "autonomia_agent_id", null: false
    t.bigint "account_id", null: false
    t.bigint "source_id"
    t.text "content", null: false
    t.vector "embedding", limit: 1536
    t.integer "status", default: 1, null: false
    t.integer "chunk_index", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.halfvec "embedding_large", limit: 3072
    t.index ["account_id"], name: "index_autonomia_agent_knowledge_on_account_id"
    t.index ["autonomia_agent_id", "status"], name: "idx_autonomia_knowledge_agent_status"
    t.index ["autonomia_agent_id"], name: "index_autonomia_agent_knowledge_on_autonomia_agent_id"
    t.index ["embedding"], name: "idx_autonomia_knowledge_embedding", using: :ivfflat
    t.index ["embedding_large"], name: "idx_autonomia_knowledge_embedding_large", opclass: :halfvec_cosine_ops, using: :hnsw
    t.index ["source_id"], name: "index_autonomia_agent_knowledge_on_source_id"
  end

  create_table "autonomia_agent_sources", force: :cascade do |t|
    t.bigint "autonomia_agent_id", null: false
    t.bigint "account_id", null: false
    t.string "source_type", null: false
    t.string "reference"
    t.string "external_link"
    t.integer "status", default: 0, null: false
    t.string "sync_status"
    t.string "sync_token"
    t.text "error"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "quality_score"
    t.string "confidence"
    t.string "review_status"
    t.text "review_summary"
    t.string "review_label"
    t.text "review_reason"
    t.datetime "reviewed_at"
    t.integer "kind", default: 0, null: false
    t.index ["account_id"], name: "index_autonomia_agent_sources_on_account_id"
    t.index ["autonomia_agent_id", "kind"], name: "index_autonomia_agent_sources_on_autonomia_agent_id_and_kind"
    t.index ["autonomia_agent_id", "status"], name: "index_autonomia_agent_sources_on_autonomia_agent_id_and_status"
    t.index ["autonomia_agent_id"], name: "index_autonomia_agent_sources_on_autonomia_agent_id"
  end

  create_table "autonomia_agents", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.string "agent_type", default: "support", null: false
    t.integer "status", default: 0, null: false
    t.integer "mode", default: 0, null: false
    t.text "instruction"
    t.text "scaffold"
    t.text "human_card"
    t.text "greeting"
    t.text "fallback_message"
    t.text "handoff_rule"
    t.jsonb "starter_questions", default: [], null: false
    t.string "tone"
    t.jsonb "config", default: {}, null: false
    t.boolean "enabled", default: false, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "actuation", default: 0, null: false
    t.index ["account_id", "actuation"], name: "idx_autonomia_agents_account_actuation"
    t.index ["account_id", "agent_type"], name: "index_autonomia_agents_on_account_id_and_agent_type"
    t.index ["account_id", "status"], name: "index_autonomia_agents_on_account_id_and_status"
    t.index ["account_id"], name: "index_autonomia_agents_on_account_id"
    t.index ["created_by_id"], name: "index_autonomia_agents_on_created_by_id"
  end

  create_table "autonomia_prospecting_leads", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "prospect_search_id"
    t.bigint "contact_id"
    t.bigint "crm_card_id"
    t.string "provider", default: "mock", null: false
    t.string "provider_place_id"
    t.string "name", null: false
    t.string "phone"
    t.string "website"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "country"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.decimal "rating", precision: 3, scale: 2
    t.integer "reviews_count"
    t.string "category"
    t.string "dedupe_key", null: false
    t.integer "status", default: 0, null: false
    t.string "discard_reason"
    t.jsonb "raw_payload", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "dedupe_key"], name: "index_autonomia_prospecting_leads_on_account_id_and_dedupe_key", unique: true
    t.index ["account_id", "provider", "provider_place_id"], name: "idx_autonomia_prospecting_leads_provider_place", unique: true, where: "(provider_place_id IS NOT NULL)"
    t.index ["account_id", "status"], name: "index_autonomia_prospecting_leads_on_account_id_and_status"
    t.index ["account_id"], name: "index_autonomia_prospecting_leads_on_account_id"
    t.index ["contact_id"], name: "index_autonomia_prospecting_leads_on_contact_id"
    t.index ["crm_card_id"], name: "index_autonomia_prospecting_leads_on_crm_card_id"
    t.index ["prospect_search_id"], name: "index_autonomia_prospecting_leads_on_search_id"
  end

  create_table "autonomia_prospecting_list_leads", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "prospect_list_id", null: false
    t.bigint "prospect_lead_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_autonomia_prospecting_list_leads_on_account_id"
    t.index ["prospect_lead_id"], name: "idx_autonomia_prospecting_list_leads_lead_id"
    t.index ["prospect_list_id", "prospect_lead_id"], name: "idx_autonomia_prospecting_list_leads_unique", unique: true
    t.index ["prospect_list_id"], name: "idx_autonomia_prospecting_list_leads_list_id"
  end

  create_table "autonomia_prospecting_lists", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id"
    t.string "name", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "name"], name: "index_autonomia_prospecting_lists_on_account_id_and_name"
    t.index ["account_id"], name: "index_autonomia_prospecting_lists_on_account_id"
    t.index ["user_id"], name: "index_autonomia_prospecting_lists_on_user_id"
  end

  create_table "autonomia_prospecting_searches", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id"
    t.string "query", null: false
    t.string "location"
    t.integer "radius"
    t.string "provider", default: "mock", null: false
    t.integer "status", default: 0, null: false
    t.integer "requested_limit", default: 20, null: false
    t.integer "consumed_api_units", default: 0, null: false
    t.string "cache_fingerprint"
    t.datetime "cache_expires_at"
    t.jsonb "categories", default: [], null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "cache_fingerprint"], name: "idx_autonomia_prospecting_searches_acc_cache_fp"
    t.index ["account_id", "created_at"], name: "idx_autonomia_prospecting_searches_acc_created"
    t.index ["account_id"], name: "index_autonomia_prospecting_searches_on_account_id"
    t.index ["user_id"], name: "index_autonomia_prospecting_searches_on_user_id"
  end

  create_table "autonomia_prospecting_settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "provider_enabled", default: false, null: false
    t.string "provider", default: "mock", null: false
    t.integer "default_limit", default: 20, null: false
    t.integer "max_results_per_search", default: 20, null: false
    t.integer "daily_limit"
    t.integer "monthly_limit"
    t.integer "cache_ttl_seconds", default: 86400, null: false
    t.boolean "enrichment_enabled", default: false, null: false
    t.string "google_places_api_key"
    t.bigint "default_crm_pipeline_id"
    t.bigint "default_crm_stage_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_autonomia_prospecting_settings_on_account_id", unique: true
    t.index ["default_crm_pipeline_id"], name: "idx_autonomia_prospecting_settings_default_pipeline"
    t.index ["default_crm_stage_id"], name: "idx_autonomia_prospecting_settings_default_stage"
  end

  create_table "calls", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "message_id"
    t.bigint "accepted_by_agent_id"
    t.string "provider_call_id", null: false
    t.integer "provider", default: 0, null: false
    t.integer "direction", null: false
    t.string "status", default: "ringing", null: false
    t.datetime "started_at"
    t.integer "duration_seconds"
    t.string "end_reason"
    t.jsonb "meta", default: {}
    t.text "transcript"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "contact_id"], name: "index_calls_on_account_id_and_contact_id"
    t.index ["account_id", "conversation_id"], name: "index_calls_on_account_id_and_conversation_id"
    t.index ["message_id"], name: "index_calls_on_message_id"
    t.index ["provider", "provider_call_id"], name: "index_calls_on_provider_and_provider_call_id", unique: true
  end

  create_table "campaign_import_labels", force: :cascade do |t|
    t.bigint "campaign_import_id", null: false
    t.bigint "label_id"
    t.string "title", null: false
    t.integer "kind", default: 0, null: false
    t.integer "batch_index"
    t.integer "planned_count", default: 0, null: false
    t.integer "applied_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_import_id", "title"], name: "idx_campaign_import_labels_on_import_and_title", unique: true
    t.index ["campaign_import_id"], name: "index_campaign_import_labels_on_campaign_import_id"
    t.index ["label_id"], name: "index_campaign_import_labels_on_label_id"
  end

  create_table "campaign_import_rows", force: :cascade do |t|
    t.bigint "campaign_import_id", null: false
    t.integer "row_number", null: false
    t.string "raw_name"
    t.string "raw_phone_masked"
    t.string "normalized_name"
    t.string "normalized_phone_hash"
    t.bigint "contact_id"
    t.boolean "was_existing_contact", default: false, null: false
    t.jsonb "labels_applied", default: [], null: false
    t.integer "batch_index"
    t.integer "status", default: 0, null: false
    t.jsonb "error_messages", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_import_id", "row_number"], name: "idx_campaign_import_rows_on_import_and_row_number", unique: true
    t.index ["campaign_import_id", "status"], name: "index_campaign_import_rows_on_campaign_import_id_and_status"
    t.index ["campaign_import_id"], name: "index_campaign_import_rows_on_campaign_import_id"
    t.index ["contact_id"], name: "index_campaign_import_rows_on_contact_id"
    t.index ["normalized_phone_hash"], name: "index_campaign_import_rows_on_normalized_phone_hash"
  end

  create_table "campaign_imports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.bigint "data_import_id"
    t.integer "status", default: 0, null: false
    t.integer "undo_status", default: 0, null: false
    t.string "source_filename"
    t.string "source_content_type"
    t.string "source_format"
    t.bigint "source_byte_size"
    t.integer "total_rows", default: 0, null: false
    t.integer "valid_rows", default: 0, null: false
    t.integer "invalid_rows", default: 0, null: false
    t.integer "duplicate_file_rows", default: 0, null: false
    t.integer "imported_contacts_count", default: 0, null: false
    t.integer "existing_contacts_count", default: 0, null: false
    t.integer "failed_contacts_count", default: 0, null: false
    t.integer "new_contacts_estimate", default: 0, null: false
    t.integer "processed_records", default: 0, null: false
    t.integer "failed_records", default: 0, null: false
    t.integer "new_contacts_count", default: 0, null: false
    t.integer "existing_contacts_updated_count", default: 0, null: false
    t.string "mode"
    t.string "campaign_name"
    t.string "campaign_slug"
    t.string "base_label"
    t.integer "batch_count", default: 0, null: false
    t.jsonb "labels_payload", default: {}, null: false
    t.jsonb "validation_summary", default: {}, null: false
    t.jsonb "options", default: {}, null: false
    t.datetime "started_at"
    t.datetime "validated_at"
    t.datetime "confirmed_at"
    t.datetime "queued_at"
    t.datetime "import_started_at"
    t.datetime "import_finished_at"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.datetime "undo_started_at"
    t.datetime "undo_finished_at"
    t.datetime "undo_completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "campaign_slug"], name: "index_campaign_imports_on_account_id_and_campaign_slug"
    t.index ["account_id", "created_at"], name: "index_campaign_imports_on_account_id_and_created_at"
    t.index ["account_id", "status"], name: "index_campaign_imports_on_account_id_and_status"
    t.index ["account_id"], name: "index_campaign_imports_on_account_id"
    t.index ["data_import_id"], name: "index_campaign_imports_on_data_import_id"
    t.index ["user_id"], name: "index_campaign_imports_on_user_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.integer "display_id", null: false
    t.string "title", null: false
    t.text "description"
    t.text "message", null: false
    t.integer "sender_id"
    t.boolean "enabled", default: true
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.jsonb "trigger_rules", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "campaign_type", default: 0, null: false
    t.integer "campaign_status", default: 0, null: false
    t.jsonb "audience", default: []
    t.datetime "scheduled_at", precision: nil
    t.boolean "trigger_only_during_business_hours", default: false
    t.jsonb "template_params"
    t.index ["account_id"], name: "index_campaigns_on_account_id"
    t.index ["campaign_status"], name: "index_campaigns_on_campaign_status"
    t.index ["campaign_type"], name: "index_campaigns_on_campaign_type"
    t.index ["inbox_id"], name: "index_campaigns_on_inbox_id"
    t.index ["scheduled_at"], name: "index_campaigns_on_scheduled_at"
  end

  create_table "canned_responses", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "short_code"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "captain_assistant_responses", force: :cascade do |t|
    t.string "question", null: false
    t.text "answer", null: false
    t.vector "embedding", limit: 1536
    t.bigint "assistant_id", null: false
    t.bigint "documentable_id"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 1, null: false
    t.string "documentable_type"
    t.boolean "edited", default: false, null: false
    t.index ["account_id"], name: "index_captain_assistant_responses_on_account_id"
    t.index ["assistant_id"], name: "index_captain_assistant_responses_on_assistant_id"
    t.index ["documentable_id", "documentable_type"], name: "idx_cap_asst_resp_on_documentable"
    t.index ["embedding"], name: "vector_idx_knowledge_entries_embedding", using: :ivfflat
    t.index ["status"], name: "index_captain_assistant_responses_on_status"
  end

  create_table "captain_assistants", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "account_id", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "config", default: {}, null: false
    t.jsonb "response_guidelines", default: []
    t.jsonb "guardrails", default: []
    t.index ["account_id"], name: "index_captain_assistants_on_account_id"
  end

  create_table "captain_custom_tools", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description"
    t.string "http_method", default: "GET", null: false
    t.text "endpoint_url", null: false
    t.text "request_template"
    t.text "response_template"
    t.string "auth_type", default: "none"
    t.jsonb "auth_config", default: {}
    t.jsonb "param_schema", default: []
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "slug"], name: "index_captain_custom_tools_on_account_id_and_slug", unique: true
    t.index ["account_id"], name: "index_captain_custom_tools_on_account_id"
  end

  create_table "captain_documents", force: :cascade do |t|
    t.string "name"
    t.text "external_link", null: false
    t.text "content"
    t.bigint "assistant_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "metadata", default: {}
    t.integer "sync_status"
    t.datetime "last_synced_at"
    t.datetime "last_sync_attempted_at"
    t.index "assistant_id, md5(external_link)", name: "idx_captain_documents_on_assistant_id_and_external_link_md5", unique: true
    t.index ["account_id", "assistant_id", "sync_status", "last_synced_at"], name: "idx_captain_documents_on_account_assistant_sync_stats"
    t.index ["account_id", "sync_status"], name: "index_captain_documents_on_account_id_and_sync_status"
    t.index ["account_id"], name: "index_captain_documents_on_account_id"
    t.index ["assistant_id"], name: "index_captain_documents_on_assistant_id"
    t.index ["status"], name: "index_captain_documents_on_status"
  end

  create_table "captain_inboxes", force: :cascade do |t|
    t.bigint "captain_assistant_id", null: false
    t.bigint "inbox_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["captain_assistant_id", "inbox_id"], name: "index_captain_inboxes_on_captain_assistant_id_and_inbox_id", unique: true
    t.index ["captain_assistant_id"], name: "index_captain_inboxes_on_captain_assistant_id"
    t.index ["inbox_id"], name: "index_captain_inboxes_on_inbox_id"
  end

  create_table "captain_scenarios", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.text "instruction"
    t.jsonb "tools", default: []
    t.boolean "enabled", default: true, null: false
    t.bigint "assistant_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_captain_scenarios_on_account_id"
    t.index ["assistant_id", "enabled"], name: "index_captain_scenarios_on_assistant_id_and_enabled"
    t.index ["assistant_id"], name: "index_captain_scenarios_on_assistant_id"
    t.index ["enabled"], name: "index_captain_scenarios_on_enabled"
  end

  create_table "categories", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "portal_id", null: false
    t.string "name"
    t.text "description"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale", default: "en"
    t.string "slug", null: false
    t.bigint "parent_category_id"
    t.bigint "associated_category_id"
    t.string "icon", default: ""
    t.string "icon_color", default: ""
    t.index ["associated_category_id"], name: "index_categories_on_associated_category_id"
    t.index ["locale", "account_id"], name: "index_categories_on_locale_and_account_id"
    t.index ["locale"], name: "index_categories_on_locale"
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
    t.index ["slug", "locale", "portal_id"], name: "index_categories_on_slug_and_locale_and_portal_id", unique: true
  end

  create_table "channel_api", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "webhook_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.string "hmac_token"
    t.boolean "hmac_mandatory", default: false
    t.jsonb "additional_attributes", default: {}
    t.string "secret"
    t.index ["hmac_token"], name: "index_channel_api_on_hmac_token", unique: true
    t.index ["identifier"], name: "index_channel_api_on_identifier", unique: true
  end

  create_table "channel_email", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "email", null: false
    t.string "forward_to_email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "imap_enabled", default: false
    t.string "imap_address", default: ""
    t.integer "imap_port", default: 0
    t.string "imap_login", default: ""
    t.string "imap_password", default: ""
    t.boolean "imap_enable_ssl", default: true
    t.boolean "smtp_enabled", default: false
    t.string "smtp_address", default: ""
    t.integer "smtp_port", default: 0
    t.string "smtp_login", default: ""
    t.string "smtp_password", default: ""
    t.string "smtp_domain", default: ""
    t.boolean "smtp_enable_starttls_auto", default: true
    t.string "smtp_authentication", default: "login"
    t.string "smtp_openssl_verify_mode", default: "none"
    t.boolean "smtp_enable_ssl_tls", default: false
    t.jsonb "provider_config", default: {}
    t.string "provider"
    t.boolean "verified_for_sending", default: false, null: false
    t.string "imap_authentication", default: "plain"
    t.boolean "calendar_enabled", default: false, null: false
    t.boolean "calendar_scope_granted", default: false, null: false
    t.string "calendar_identity"
    t.boolean "calendar_shared", default: false, null: false
    t.index ["account_id", "calendar_enabled"], name: "idx_channel_email_calendar_enabled"
    t.index ["email"], name: "index_channel_email_on_email", unique: true
    t.index ["forward_to_email"], name: "index_channel_email_on_forward_to_email", unique: true
  end

  create_table "channel_facebook_pages", id: :serial, force: :cascade do |t|
    t.string "page_id", null: false
    t.string "user_access_token", null: false
    t.string "page_access_token", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "instagram_id"
    t.index ["page_id", "account_id"], name: "index_channel_facebook_pages_on_page_id_and_account_id", unique: true
    t.index ["page_id"], name: "index_channel_facebook_pages_on_page_id"
  end

  create_table "channel_instagram", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "expires_at", null: false
    t.integer "account_id", null: false
    t.string "instagram_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instagram_id"], name: "index_channel_instagram_on_instagram_id", unique: true
  end

  create_table "channel_line", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "line_channel_id", null: false
    t.string "line_channel_secret", null: false
    t.string "line_channel_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_channel_id"], name: "index_channel_line_on_line_channel_id", unique: true
  end

  create_table "channel_sms", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone_number"], name: "index_channel_sms_on_phone_number", unique: true
  end

  create_table "channel_telegram", force: :cascade do |t|
    t.string "bot_name"
    t.integer "account_id", null: false
    t.string "bot_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bot_token"], name: "index_channel_telegram_on_bot_token", unique: true
  end

  create_table "channel_tiktok", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "business_id", null: false
    t.string "access_token", null: false
    t.datetime "expires_at", null: false
    t.string "refresh_token", null: false
    t.datetime "refresh_token_expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_channel_tiktok_on_business_id", unique: true
  end

  create_table "channel_twilio_sms", force: :cascade do |t|
    t.string "phone_number"
    t.string "auth_token", null: false
    t.string "account_sid", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "medium", default: 0
    t.string "messaging_service_sid"
    t.string "api_key_sid"
    t.jsonb "content_templates", default: {}
    t.datetime "content_templates_last_updated"
    t.boolean "voice_enabled", default: false, null: false
    t.string "twiml_app_sid"
    t.string "api_key_secret"
    t.jsonb "provider_config", default: {}
    t.index ["account_sid", "phone_number"], name: "index_channel_twilio_sms_on_account_sid_and_phone_number", unique: true
    t.index ["messaging_service_sid"], name: "index_channel_twilio_sms_on_messaging_service_sid", unique: true
    t.index ["phone_number"], name: "index_channel_twilio_sms_on_phone_number", unique: true
  end

  create_table "channel_twitter_profiles", force: :cascade do |t|
    t.string "profile_id", null: false
    t.string "twitter_access_token", null: false
    t.string "twitter_access_token_secret", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "tweets_enabled", default: true
    t.index ["account_id", "profile_id"], name: "index_channel_twitter_profiles_on_account_id_and_profile_id", unique: true
  end

  create_table "channel_web_widgets", id: :serial, force: :cascade do |t|
    t.string "website_url"
    t.integer "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "website_token"
    t.string "widget_color", default: "#1f93ff"
    t.string "welcome_title"
    t.string "welcome_tagline"
    t.integer "feature_flags", default: 7, null: false
    t.integer "reply_time", default: 0
    t.string "hmac_token"
    t.boolean "pre_chat_form_enabled", default: false
    t.jsonb "pre_chat_form_options", default: {}
    t.boolean "hmac_mandatory", default: false
    t.boolean "continuity_via_email", default: true, null: false
    t.text "allowed_domains", default: ""
    t.index ["hmac_token"], name: "index_channel_web_widgets_on_hmac_token", unique: true
    t.index ["website_token"], name: "index_channel_web_widgets_on_website_token", unique: true
  end

  create_table "channel_whatsapp", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "message_templates", default: {}
    t.datetime "message_templates_last_updated", precision: nil
    t.index ["phone_number"], name: "index_channel_whatsapp_on_phone_number", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "domain"
    t.text "description"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "contacts_count", default: 0, null: false
    t.jsonb "additional_attributes", default: {}
    t.jsonb "custom_attributes", default: {}
    t.datetime "last_activity_at", precision: nil
    t.index ["account_id", "domain"], name: "index_companies_on_account_and_domain", unique: true, where: "(domain IS NOT NULL)"
    t.index ["account_id"], name: "index_companies_on_account_id"
    t.index ["name", "account_id"], name: "index_companies_on_name_and_account_id"
  end

  create_table "contact_inboxes", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "inbox_id"
    t.text "source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hmac_verified", default: false
    t.string "pubsub_token"
    t.index ["contact_id"], name: "index_contact_inboxes_on_contact_id"
    t.index ["inbox_id", "source_id"], name: "index_contact_inboxes_on_inbox_id_and_source_id", unique: true
    t.index ["inbox_id"], name: "index_contact_inboxes_on_inbox_id"
    t.index ["pubsub_token"], name: "index_contact_inboxes_on_pubsub_token", unique: true
    t.index ["source_id"], name: "index_contact_inboxes_on_source_id"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "name", default: ""
    t.string "email"
    t.string "phone_number"
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "additional_attributes", default: {}
    t.string "identifier"
    t.jsonb "custom_attributes", default: {}
    t.datetime "last_activity_at", precision: nil
    t.integer "contact_type", default: 0
    t.string "middle_name", default: ""
    t.string "last_name", default: ""
    t.string "location", default: ""
    t.string "country_code", default: ""
    t.boolean "blocked", default: false, null: false
    t.bigint "company_id"
    t.index "lower((email)::text), account_id", name: "index_contacts_on_lower_email_account_id"
    t.index ["account_id", "contact_type"], name: "index_contacts_on_account_id_and_contact_type"
    t.index ["account_id", "email", "phone_number", "identifier"], name: "index_contacts_on_nonempty_fields", where: "(((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))"
    t.index ["account_id", "last_activity_at"], name: "index_contacts_on_account_id_and_last_activity_at", order: { last_activity_at: "DESC NULLS LAST" }
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["account_id"], name: "index_resolved_contact_account_id", where: "(((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))"
    t.index ["blocked"], name: "index_contacts_on_blocked"
    t.index ["company_id"], name: "index_contacts_on_company_id"
    t.index ["email", "account_id"], name: "uniq_email_per_account_contact", unique: true
    t.index ["identifier", "account_id"], name: "uniq_identifier_per_account_contact", unique: true
    t.index ["name", "email", "phone_number", "identifier"], name: "index_contacts_on_name_email_phone_number_identifier", opclass: :gin_trgm_ops, using: :gin
    t.index ["phone_number", "account_id"], name: "index_contacts_on_phone_number_and_account_id"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_conversation_participants_on_account_id"
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id", "conversation_id"], name: "index_conversation_participants_on_user_id_and_conversation_id", unique: true
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "inbox_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "assignee_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "contact_id"
    t.integer "display_id", null: false
    t.datetime "contact_last_seen_at", precision: nil
    t.datetime "agent_last_seen_at", precision: nil
    t.jsonb "additional_attributes", default: {}
    t.bigint "contact_inbox_id"
    t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
    t.string "identifier"
    t.datetime "last_activity_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.bigint "team_id"
    t.bigint "campaign_id"
    t.datetime "snoozed_until", precision: nil
    t.jsonb "custom_attributes", default: {}
    t.datetime "assignee_last_seen_at", precision: nil
    t.datetime "first_reply_created_at", precision: nil
    t.integer "priority"
    t.bigint "sla_policy_id"
    t.datetime "waiting_since"
    t.text "cached_label_list"
    t.bigint "assignee_agent_bot_id"
    t.index ["account_id", "display_id"], name: "index_conversations_on_account_id_and_display_id", unique: true
    t.index ["account_id", "id"], name: "index_conversations_on_id_and_account_id"
    t.index ["account_id", "inbox_id", "status", "assignee_id"], name: "conv_acid_inbid_stat_asgnid_idx"
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["assignee_id", "account_id"], name: "index_conversations_on_assignee_id_and_account_id"
    t.index ["campaign_id"], name: "index_conversations_on_campaign_id"
    t.index ["contact_id"], name: "index_conversations_on_contact_id"
    t.index ["contact_inbox_id"], name: "index_conversations_on_contact_inbox_id"
    t.index ["first_reply_created_at"], name: "index_conversations_on_first_reply_created_at"
    t.index ["identifier", "account_id"], name: "index_conversations_on_identifier_and_account_id"
    t.index ["inbox_id"], name: "index_conversations_on_inbox_id"
    t.index ["priority"], name: "index_conversations_on_priority"
    t.index ["status", "account_id"], name: "index_conversations_on_status_and_account_id"
    t.index ["status", "priority"], name: "index_conversations_on_status_and_priority"
    t.index ["team_id"], name: "index_conversations_on_team_id"
    t.index ["uuid"], name: "index_conversations_on_uuid", unique: true
    t.index ["waiting_since"], name: "index_conversations_on_waiting_since"
  end

  create_table "copilot_messages", force: :cascade do |t|
    t.bigint "copilot_thread_id", null: false
    t.bigint "account_id", null: false
    t.jsonb "message", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "message_type", default: 0
    t.index ["account_id"], name: "index_copilot_messages_on_account_id"
    t.index ["copilot_thread_id"], name: "index_copilot_messages_on_copilot_thread_id"
  end

  create_table "copilot_threads", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assistant_id"
    t.index ["account_id"], name: "index_copilot_threads_on_account_id"
    t.index ["assistant_id"], name: "index_copilot_threads_on_assistant_id"
    t.index ["user_id"], name: "index_copilot_threads_on_user_id"
  end

  create_table "crm_activities", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "card_id", null: false
    t.bigint "conversation_id"
    t.string "actor_type"
    t.bigint "actor_id"
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["account_id", "card_id", "created_at"], name: "idx_crm_activities_card_time"
    t.index ["account_id", "event_type", "created_at"], name: "idx_crm_activities_event_time"
    t.index ["account_id"], name: "index_crm_activities_on_account_id"
    t.index ["card_id"], name: "index_crm_activities_on_card_id"
    t.index ["conversation_id"], name: "index_crm_activities_on_conversation_id"
  end

  create_table "crm_agent_booking_links", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "booking_profile_id", null: false
    t.bigint "agent_id", null: false
    t.bigint "inbox_id", null: false
    t.string "slug", null: false
    t.boolean "enabled", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_crm_agent_booking_links_on_account_id"
    t.index ["agent_id"], name: "index_crm_agent_booking_links_on_agent_id"
    t.index ["booking_profile_id", "agent_id"], name: "idx_crm_booking_links_profile_agent", unique: true
    t.index ["booking_profile_id"], name: "index_crm_agent_booking_links_on_booking_profile_id"
    t.index ["inbox_id"], name: "index_crm_agent_booking_links_on_inbox_id"
    t.index ["slug"], name: "index_crm_agent_booking_links_on_slug", unique: true
  end

  create_table "crm_agent_booking_profiles", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.string "slug", null: false
    t.string "title"
    t.text "description"
    t.integer "duration_minutes", default: 30, null: false
    t.integer "buffer_minutes", default: 0, null: false
    t.integer "booking_window_days", default: 14, null: false
    t.jsonb "working_hours", default: {}, null: false
    t.string "timezone"
    t.boolean "enabled", default: true, null: false
    t.bigint "default_pipeline_id"
    t.bigint "default_stage_id"
    t.bigint "default_assignee_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assignment_mode", default: 0, null: false
    t.index ["account_id"], name: "index_crm_agent_booking_profiles_on_account_id"
    t.index ["inbox_id"], name: "index_crm_agent_booking_profiles_on_inbox_id"
    t.index ["slug"], name: "index_crm_agent_booking_profiles_on_slug", unique: true
  end

  create_table "crm_ai_stage_suggestions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "card_id", null: false
    t.bigint "from_stage_id", null: false
    t.bigint "to_stage_id", null: false
    t.decimal "confidence", precision: 5, scale: 4, null: false
    t.string "reasoning", limit: 500
    t.string "model_used", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status", "created_at"], name: "idx_crm_ai_suggestions_account_status_created"
    t.index ["account_id"], name: "index_crm_ai_stage_suggestions_on_account_id"
    t.index ["card_id", "status", "created_at"], name: "idx_crm_ai_suggestions_card_status_created"
    t.index ["card_id"], name: "index_crm_ai_stage_suggestions_on_card_id"
    t.index ["from_stage_id"], name: "index_crm_ai_stage_suggestions_on_from_stage_id"
    t.index ["to_stage_id"], name: "index_crm_ai_stage_suggestions_on_to_stage_id"
  end

  create_table "crm_ai_usage_events", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "pipeline_id"
    t.string "feature", null: false
    t.string "model", null: false
    t.string "reasoning_effort"
    t.integer "input_tokens", default: 0, null: false
    t.integer "cached_tokens", default: 0, null: false
    t.integer "output_tokens", default: 0, null: false
    t.decimal "cost_estimate", precision: 12, scale: 6, default: "0.0", null: false
    t.integer "latency_ms"
    t.datetime "created_at", null: false
    t.index ["account_id", "created_at"], name: "idx_crm_ai_usage_account_created"
    t.index ["account_id", "feature", "created_at"], name: "idx_crm_ai_usage_account_feature_created"
  end

  create_table "crm_calendar_sync_states", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.integer "provider", default: 0, null: false
    t.string "channel_id"
    t.string "resource_id"
    t.string "verification_token"
    t.datetime "expires_at"
    t.integer "status", default: 0, null: false
    t.datetime "last_notified_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_crm_calendar_sync_states_on_account_id"
    t.index ["channel_id"], name: "index_crm_calendar_sync_states_on_channel_id"
    t.index ["expires_at"], name: "index_crm_calendar_sync_states_on_expires_at"
    t.index ["inbox_id"], name: "index_crm_calendar_sync_states_on_inbox_id", unique: true
  end

  create_table "crm_card_conversations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "card_id", null: false
    t.bigint "conversation_id", null: false
    t.boolean "is_primary", default: false, null: false
    t.bigint "linked_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "card_id", "conversation_id"], name: "idx_crm_card_conversations_unique", unique: true
    t.index ["account_id", "card_id"], name: "idx_crm_card_conversations_card"
    t.index ["account_id", "conversation_id"], name: "idx_crm_card_conversations_conversation"
    t.index ["account_id"], name: "index_crm_card_conversations_on_account_id"
    t.index ["card_id"], name: "index_crm_card_conversations_on_card_id"
    t.index ["conversation_id"], name: "index_crm_card_conversations_on_conversation_id"
    t.index ["linked_by_id"], name: "index_crm_card_conversations_on_linked_by_id"
  end

  create_table "crm_cards", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "pipeline_id", null: false
    t.bigint "stage_id", null: false
    t.bigint "contact_id"
    t.bigint "conversation_id"
    t.bigint "inbox_id"
    t.bigint "owner_id"
    t.bigint "team_id"
    t.string "title", null: false
    t.text "description"
    t.bigint "value_cents", default: 0, null: false
    t.string "currency", default: "BRL", null: false
    t.integer "status", default: 0, null: false
    t.text "lost_reason"
    t.string "source"
    t.integer "priority", default: 1, null: false
    t.integer "score", default: 0, null: false
    t.datetime "entered_stage_at"
    t.datetime "last_activity_at"
    t.datetime "last_message_at"
    t.datetime "expected_close_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "next_follow_up_at"
    t.datetime "closed_at"
    t.string "external_id"
    t.index "lower((title)::text) gin_trgm_ops", name: "idx_crm_cards_title_trgm", using: :gin
    t.index ["account_id", "contact_id"], name: "idx_crm_cards_contact"
    t.index ["account_id", "conversation_id", "status", "id"], name: "idx_crm_cards_conversation"
    t.index ["account_id", "entered_stage_at"], name: "idx_crm_cards_entered_stage"
    t.index ["account_id", "external_id"], name: "uniq_crm_cards_external_id_per_account", unique: true, where: "(external_id IS NOT NULL)"
    t.index ["account_id", "inbox_id", "owner_id"], name: "idx_crm_cards_inbox_owner"
    t.index ["account_id", "inbox_id", "status", "id"], name: "idx_crm_cards_visible_inbox"
    t.index ["account_id", "last_message_at"], name: "idx_crm_cards_last_message"
    t.index ["account_id", "next_follow_up_at"], name: "idx_crm_cards_next_follow_up"
    t.index ["account_id", "owner_id", "status", "id"], name: "idx_crm_cards_owner"
    t.index ["account_id", "pipeline_id", "expected_close_at", "id"], name: "idx_crm_cards_calendar"
    t.index ["account_id", "pipeline_id", "stage_id", "status", "id"], name: "idx_crm_cards_board"
    t.index ["account_id", "pipeline_id", "stage_id", "status", "inbox_id", "id"], name: "idx_crm_cards_board_inbox"
    t.index ["account_id", "pipeline_id", "stage_id", "status", "next_follow_up_at", "id"], name: "idx_crm_cards_board_follow_up"
    t.index ["account_id", "pipeline_id", "stage_id", "status", "owner_id", "id"], name: "idx_crm_cards_board_owner"
    t.index ["account_id", "pipeline_id", "stage_id", "status", "priority", "id"], name: "idx_crm_cards_board_priority"
    t.index ["account_id", "pipeline_id", "stage_id", "status", "team_id", "id"], name: "idx_crm_cards_board_team"
    t.index ["account_id", "pipeline_id", "status", "closed_at"], name: "idx_crm_cards_account_pipeline_status_closed"
    t.index ["account_id", "status", "created_at"], name: "idx_crm_cards_status_created"
    t.index ["account_id", "updated_at", "id"], name: "idx_crm_cards_account_updated"
    t.index ["account_id"], name: "index_crm_cards_on_account_id"
    t.index ["contact_id"], name: "index_crm_cards_on_contact_id"
    t.index ["conversation_id"], name: "idx_crm_cards_unique_open_conversation", unique: true, where: "((conversation_id IS NOT NULL) AND (status = 0))"
    t.index ["conversation_id"], name: "index_crm_cards_on_conversation_id"
    t.index ["inbox_id"], name: "index_crm_cards_on_inbox_id"
    t.index ["owner_id"], name: "index_crm_cards_on_owner_id"
    t.index ["pipeline_id"], name: "index_crm_cards_on_pipeline_id"
    t.index ["stage_id"], name: "index_crm_cards_on_stage_id"
    t.index ["team_id"], name: "index_crm_cards_on_team_id"
  end

  create_table "crm_follow_ups", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "card_id", null: false
    t.bigint "conversation_id"
    t.bigint "contact_id"
    t.bigint "inbox_id"
    t.bigint "assignee_id"
    t.string "title", null: false
    t.text "description"
    t.integer "follow_up_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "automation_mode", default: 0, null: false
    t.datetime "due_at", null: false
    t.string "timezone", default: "UTC", null: false
    t.datetime "completed_at"
    t.datetime "canceled_at"
    t.bigint "created_by_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "assignee_id", "due_at", "status"], name: "idx_crm_followups_assignee_due"
    t.index ["account_id", "card_id"], name: "idx_crm_followups_card"
    t.index ["account_id", "conversation_id"], name: "idx_crm_followups_conversation"
    t.index ["account_id", "status", "due_at"], name: "idx_crm_followups_status_due"
    t.index ["account_id"], name: "index_crm_follow_ups_on_account_id"
    t.index ["assignee_id"], name: "index_crm_follow_ups_on_assignee_id"
    t.index ["card_id"], name: "index_crm_follow_ups_on_card_id"
    t.index ["contact_id"], name: "index_crm_follow_ups_on_contact_id"
    t.index ["conversation_id"], name: "index_crm_follow_ups_on_conversation_id"
    t.index ["created_by_id"], name: "index_crm_follow_ups_on_created_by_id"
    t.index ["inbox_id"], name: "index_crm_follow_ups_on_inbox_id"
    t.index ["status", "due_at", "id"], name: "idx_crm_followups_due_processor"
  end

  create_table "crm_inbox_settings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.boolean "crm_enabled", default: false, null: false
    t.bigint "default_pipeline_id"
    t.bigint "default_stage_id"
    t.integer "visibility_mode", default: 0, null: false
    t.boolean "auto_create_card", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "crm_enabled"], name: "index_crm_inbox_settings_on_account_id_and_crm_enabled"
    t.index ["account_id", "inbox_id"], name: "index_crm_inbox_settings_on_account_id_and_inbox_id", unique: true
    t.index ["account_id"], name: "index_crm_inbox_settings_on_account_id"
    t.index ["default_pipeline_id"], name: "index_crm_inbox_settings_on_default_pipeline_id"
    t.index ["default_stage_id"], name: "index_crm_inbox_settings_on_default_stage_id"
    t.index ["inbox_id"], name: "index_crm_inbox_settings_on_inbox_id"
  end

  create_table "crm_integration_tokens", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.bigint "custom_role_id"
    t.bigint "account_user_id"
    t.bigint "created_by_id"
    t.datetime "last_used_at"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_crm_integration_tokens_on_account_id"
    t.index ["account_user_id"], name: "index_crm_integration_tokens_on_account_user_id"
    t.index ["created_by_id"], name: "index_crm_integration_tokens_on_created_by_id"
    t.index ["custom_role_id"], name: "index_crm_integration_tokens_on_custom_role_id"
  end

  create_table "crm_meeting_guests", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "meeting_id", null: false
    t.bigint "contact_id"
    t.bigint "user_id"
    t.string "email", null: false
    t.string "name"
    t.integer "guest_type", default: 0, null: false
    t.integer "rsvp_status", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "meeting_id", "email"], name: "idx_crm_meeting_guests_unique_email", unique: true
    t.index ["account_id", "meeting_id"], name: "idx_crm_meeting_guests_meeting"
    t.index ["account_id"], name: "index_crm_meeting_guests_on_account_id"
    t.index ["contact_id"], name: "idx_crm_meeting_guests_contact"
    t.index ["contact_id"], name: "index_crm_meeting_guests_on_contact_id"
    t.index ["meeting_id"], name: "index_crm_meeting_guests_on_meeting_id"
    t.index ["user_id"], name: "index_crm_meeting_guests_on_user_id"
  end

  create_table "crm_meetings", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "card_id", null: false
    t.bigint "inbox_id"
    t.bigint "created_by_id", null: false
    t.bigint "reminder_id"
    t.string "title", null: false
    t.text "description"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.string "timezone", default: "UTC", null: false
    t.integer "status", default: 0, null: false
    t.integer "provider", null: false
    t.integer "online_meeting_type", default: 0, null: false
    t.string "external_event_id"
    t.text "online_meeting_url"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "outcome"
    t.text "outcome_notes"
    t.datetime "outcome_recorded_at"
    t.index ["account_id", "card_id"], name: "idx_crm_meetings_card"
    t.index ["account_id", "created_by_id"], name: "idx_crm_meetings_created_by"
    t.index ["account_id", "inbox_id"], name: "idx_crm_meetings_inbox"
    t.index ["account_id", "outcome", "outcome_recorded_at"], name: "idx_on_account_id_outcome_outcome_recorded_at_085cfbd511"
    t.index ["account_id", "starts_at"], name: "idx_crm_meetings_starts_at"
    t.index ["account_id", "status"], name: "idx_crm_meetings_status"
    t.index ["account_id"], name: "index_crm_meetings_on_account_id"
    t.index ["card_id"], name: "index_crm_meetings_on_card_id"
    t.index ["created_by_id"], name: "index_crm_meetings_on_created_by_id"
    t.index ["external_event_id", "provider"], name: "idx_crm_meetings_external_unique", unique: true, where: "(external_event_id IS NOT NULL)"
    t.index ["inbox_id"], name: "index_crm_meetings_on_inbox_id"
    t.index ["reminder_id"], name: "index_crm_meetings_on_reminder_id"
  end

  create_table "crm_pipeline_inboxes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "pipeline_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "default_stage_id"
    t.boolean "auto_create_card", default: false, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "inbox_id"], name: "index_crm_pipeline_inboxes_on_account_id_and_inbox_id"
    t.index ["account_id", "pipeline_id", "inbox_id"], name: "idx_crm_pipeline_inboxes_unique", unique: true
    t.index ["account_id"], name: "index_crm_pipeline_inboxes_on_account_id"
    t.index ["created_by_id"], name: "index_crm_pipeline_inboxes_on_created_by_id"
    t.index ["default_stage_id"], name: "index_crm_pipeline_inboxes_on_default_stage_id"
    t.index ["inbox_id"], name: "index_crm_pipeline_inboxes_on_inbox_id"
    t.index ["pipeline_id"], name: "index_crm_pipeline_inboxes_on_pipeline_id"
  end

  create_table "crm_pipeline_stages", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "pipeline_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "color"
    t.integer "position", default: 0, null: false
    t.integer "win_probability", default: 0, null: false
    t.integer "wip_limit"
    t.integer "sla_seconds"
    t.integer "sla_warning_seconds"
    t.boolean "is_won_stage", default: false, null: false
    t.boolean "is_lost_stage", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "pipeline_id", "position"], name: "idx_crm_stages_account_pipeline_position"
    t.index ["account_id", "pipeline_id"], name: "index_crm_pipeline_stages_on_account_id_and_pipeline_id"
    t.index ["account_id"], name: "index_crm_pipeline_stages_on_account_id"
    t.index ["pipeline_id"], name: "index_crm_pipeline_stages_on_pipeline_id"
  end

  create_table "crm_pipelines", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.boolean "is_default", default: false, null: false
    t.integer "position", default: 0, null: false
    t.bigint "created_by_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "is_default"], name: "index_crm_pipelines_on_account_id_and_is_default"
    t.index ["account_id", "position"], name: "index_crm_pipelines_on_account_id_and_position"
    t.index ["account_id", "status"], name: "index_crm_pipelines_on_account_id_and_status"
    t.index ["account_id"], name: "index_crm_pipelines_on_account_id"
    t.index ["created_by_id"], name: "index_crm_pipelines_on_created_by_id"
  end

  create_table "crm_saved_views", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.bigint "pipeline_id"
    t.string "name", null: false
    t.integer "visibility", default: 0, null: false
    t.jsonb "config", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "pipeline_id"], name: "idx_crm_saved_views_account_pipeline"
    t.index ["account_id", "user_id"], name: "idx_crm_saved_views_account_user"
    t.index ["account_id", "visibility"], name: "idx_crm_saved_views_account_visibility"
    t.index ["account_id"], name: "index_crm_saved_views_on_account_id"
    t.index ["pipeline_id"], name: "index_crm_saved_views_on_pipeline_id"
    t.index ["user_id"], name: "index_crm_saved_views_on_user_id"
  end

  create_table "crm_service_schedules", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.string "timezone", null: false
    t.boolean "enabled", default: true, null: false
    t.jsonb "blocks", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "owner_type", "owner_id"], name: "idx_crm_service_schedules_owner_unique", unique: true
    t.index ["account_id"], name: "index_crm_service_schedules_on_account_id"
    t.index ["owner_type", "owner_id"], name: "index_crm_service_schedules_on_owner_type_and_owner_id"
  end

  create_table "crm_stage_automation_executions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "card_id", null: false
    t.bigint "stage_automation_id", null: false
    t.string "trigger_token", null: false
    t.integer "status", default: 0, null: false
    t.text "error_message"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_crm_stage_automation_executions_on_account_id"
    t.index ["card_id", "stage_automation_id", "trigger_token"], name: "idx_crm_stage_automation_executions_unique", unique: true
    t.index ["card_id"], name: "index_crm_stage_automation_executions_on_card_id"
    t.index ["stage_automation_id"], name: "index_crm_stage_automation_executions_on_stage_automation_id"
  end

  create_table "crm_stage_automation_steps", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "stage_automation_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "delay_seconds", default: 0, null: false
    t.integer "action_type", default: 0, null: false
    t.jsonb "action_config", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_crm_stage_automation_steps_on_account_id"
    t.index ["stage_automation_id", "position"], name: "idx_crm_stage_automation_steps_order"
    t.index ["stage_automation_id"], name: "index_crm_stage_automation_steps_on_stage_automation_id"
  end

  create_table "crm_stage_automations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "pipeline_id", null: false
    t.bigint "stage_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "trigger_event", default: 0, null: false
    t.boolean "enabled", default: true, null: false
    t.integer "position", default: 0, null: false
    t.bigint "created_by_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "stage_id", "trigger_event", "position"], name: "idx_crm_stage_automations_stage_trigger"
    t.index ["account_id"], name: "index_crm_stage_automations_on_account_id"
    t.index ["created_by_id"], name: "index_crm_stage_automations_on_created_by_id"
    t.index ["pipeline_id"], name: "index_crm_stage_automations_on_pipeline_id"
    t.index ["stage_id"], name: "index_crm_stage_automations_on_stage_id"
  end

  create_table "csat_survey_responses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "message_id", null: false
    t.integer "rating", null: false
    t.text "feedback_message"
    t.bigint "contact_id", null: false
    t.bigint "assigned_agent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "csat_review_notes"
    t.datetime "review_notes_updated_at"
    t.bigint "review_notes_updated_by_id"
    t.index ["account_id"], name: "index_csat_survey_responses_on_account_id"
    t.index ["assigned_agent_id"], name: "index_csat_survey_responses_on_assigned_agent_id"
    t.index ["contact_id"], name: "index_csat_survey_responses_on_contact_id"
    t.index ["conversation_id"], name: "index_csat_survey_responses_on_conversation_id"
    t.index ["message_id"], name: "index_csat_survey_responses_on_message_id", unique: true
    t.index ["review_notes_updated_by_id"], name: "index_csat_survey_responses_on_review_notes_updated_by_id"
  end

  create_table "custom_attribute_definitions", force: :cascade do |t|
    t.string "attribute_display_name"
    t.string "attribute_key"
    t.integer "attribute_display_type", default: 0
    t.integer "default_value"
    t.integer "attribute_model", default: 0
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "attribute_description"
    t.jsonb "attribute_values", default: []
    t.string "regex_pattern"
    t.string "regex_cue"
    t.index ["account_id"], name: "index_custom_attribute_definitions_on_account_id"
    t.index ["attribute_key", "attribute_model", "account_id"], name: "attribute_key_model_index", unique: true
  end

  create_table "custom_filters", force: :cascade do |t|
    t.string "name", null: false
    t.integer "filter_type", default: 0, null: false
    t.jsonb "query", default: "{}", null: false
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_custom_filters_on_account_id"
    t.index ["user_id"], name: "index_custom_filters_on_user_id"
  end

  create_table "custom_roles", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "account_id", null: false
    t.text "permissions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_custom_roles_on_account_id"
  end

  create_table "dashboard_apps", force: :cascade do |t|
    t.string "title", null: false
    t.jsonb "content", default: []
    t.bigint "account_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_dashboard_apps_on_account_id"
    t.index ["user_id"], name: "index_dashboard_apps_on_user_id"
  end

  create_table "data_imports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "data_type", null: false
    t.integer "status", default: 0, null: false
    t.text "processing_errors"
    t.integer "total_records"
    t.integer "processed_records"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_data_imports_on_account_id"
  end

  create_table "email_campaign_recipients", force: :cascade do |t|
    t.bigint "email_campaign_id", null: false
    t.string "name"
    t.string "email", null: false
    t.integer "status", default: 0, null: false
    t.string "ses_message_id"
    t.datetime "sent_at"
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "attempts", default: 0, null: false
    t.datetime "last_event_at"
    t.jsonb "custom_data", default: {}, null: false
    t.index "email_campaign_id, lower((email)::text)", name: "idx_email_campaign_recipients_campaign_email", unique: true
    t.index ["email_campaign_id", "status"], name: "idx_email_campaign_recipients_campaign_status"
    t.index ["email_campaign_id"], name: "index_email_campaign_recipients_on_email_campaign_id"
    t.index ["ses_message_id"], name: "index_email_campaign_recipients_on_ses_message_id"
  end

  create_table "email_campaign_templates", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name", null: false
    t.text "body_mjml"
    t.text "body_html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "category"
    t.string "thumbnail_url"
    t.index "account_id, lower((name)::text)", name: "index_email_campaign_templates_account_lower_name_unique", unique: true, where: "(account_id IS NOT NULL)"
    t.index "lower((name)::text)", name: "index_email_campaign_templates_global_lower_name_unique", unique: true, where: "(account_id IS NULL)"
    t.index ["account_id", "name"], name: "index_email_campaign_templates_on_account_id_and_name"
    t.index ["account_id"], name: "index_email_campaign_templates_on_account_id"
  end

  create_table "email_campaigns", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "sender_identity_id"
    t.string "name", null: false
    t.string "subject"
    t.string "from_name"
    t.text "body_html"
    t.string "reply_to"
    t.integer "status", default: 0, null: false
    t.datetime "scheduled_at"
    t.datetime "sent_at"
    t.integer "recipients_count", default: 0, null: false
    t.integer "sent_count", default: 0, null: false
    t.integer "failed_count", default: 0, null: false
    t.integer "suppressed_count", default: 0, null: false
    t.string "ses_configuration_set"
    t.text "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "delivered_count", default: 0, null: false
    t.integer "opened_count", default: 0, null: false
    t.integer "clicked_count", default: 0, null: false
    t.integer "bounced_count", default: 0, null: false
    t.integer "complained_count", default: 0, null: false
    t.integer "unsubscribed_count", default: 0, null: false
    t.text "body_mjml"
    t.string "preheader"
    t.string "from_email"
    t.integer "delivery_mode", default: 0, null: false
    t.bigint "sender_inbox_id"
    t.integer "ai_status", default: 0, null: false
    t.string "ai_generation_token"
    t.string "ai_provider_response_id"
    t.string "ai_error"
    t.datetime "ai_requested_at"
    t.datetime "ai_completed_at"
    t.jsonb "ai_subject_variants", default: [], null: false
    t.index ["account_id", "status", "scheduled_at"], name: "idx_email_campaigns_account_status_scheduled"
    t.index ["account_id"], name: "index_email_campaigns_on_account_id"
    t.index ["sender_identity_id"], name: "index_email_campaigns_on_sender_identity_id"
    t.index ["sender_inbox_id"], name: "index_email_campaigns_on_sender_inbox_id"
  end

  create_table "email_events", force: :cascade do |t|
    t.bigint "recipient_id", null: false
    t.integer "event_type", null: false
    t.string "url"
    t.datetime "occurred_at", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["occurred_at"], name: "idx_email_events_occurred_at"
    t.index ["recipient_id", "event_type"], name: "idx_email_events_recipient_type"
    t.index ["recipient_id"], name: "index_email_events_on_recipient_id"
  end

  create_table "email_sender_identities", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "domain", null: false
    t.string "from_email"
    t.bigint "reply_to_inbox_id"
    t.integer "status", default: 0, null: false
    t.jsonb "dkim_records", default: [], null: false
    t.string "spf_record"
    t.string "dmarc_record"
    t.string "ses_configuration_set"
    t.string "provider", default: "ses", null: false
    t.datetime "verified_at"
    t.string "last_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "account_id, lower((domain)::text)", name: "idx_email_sender_identities_account_domain", unique: true
    t.index ["account_id", "status"], name: "idx_email_sender_identities_account_status"
    t.index ["account_id"], name: "index_email_sender_identities_on_account_id"
  end

  create_table "email_suppressions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "email", null: false
    t.string "reason"
    t.string "source"
    t.datetime "created_at", null: false
    t.index "account_id, lower((email)::text)", name: "idx_email_suppressions_account_email", unique: true
    t.index ["account_id"], name: "index_email_suppressions_on_account_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", null: false
    t.integer "account_id"
    t.integer "template_type", default: 1
    t.integer "locale", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "account_id"], name: "index_email_templates_on_name_and_account_id", unique: true
  end

  create_table "folders", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "category_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "idempotency_keys", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "key", null: false
    t.string "request_fingerprint", null: false
    t.integer "response_status"
    t.jsonb "response_body"
    t.integer "state", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["account_id", "key"], name: "uniq_idempotency_keys_per_account", unique: true
    t.index ["account_id"], name: "index_idempotency_keys_on_account_id"
    t.index ["created_at"], name: "idx_idempotency_keys_created_at"
  end

  create_table "inbox_assignment_policies", force: :cascade do |t|
    t.bigint "inbox_id", null: false
    t.bigint "assignment_policy_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_policy_id"], name: "index_inbox_assignment_policies_on_assignment_policy_id"
    t.index ["inbox_id"], name: "index_inbox_assignment_policies_on_inbox_id", unique: true
  end

  create_table "inbox_capacity_limits", force: :cascade do |t|
    t.bigint "agent_capacity_policy_id", null: false
    t.bigint "inbox_id", null: false
    t.integer "conversation_limit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agent_capacity_policy_id", "inbox_id"], name: "idx_on_agent_capacity_policy_id_inbox_id_71c7ec4caf", unique: true
    t.index ["agent_capacity_policy_id"], name: "index_inbox_capacity_limits_on_agent_capacity_policy_id"
    t.index ["inbox_id"], name: "index_inbox_capacity_limits_on_inbox_id"
  end

  create_table "inbox_members", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inbox_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["inbox_id", "user_id"], name: "index_inbox_members_on_inbox_id_and_user_id", unique: true
    t.index ["inbox_id"], name: "index_inbox_members_on_inbox_id"
  end

  create_table "inboxes", id: :serial, force: :cascade do |t|
    t.integer "channel_id", null: false
    t.integer "account_id", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "channel_type"
    t.boolean "enable_auto_assignment", default: true
    t.boolean "greeting_enabled", default: false
    t.string "greeting_message"
    t.string "email_address"
    t.boolean "working_hours_enabled", default: false
    t.string "out_of_office_message"
    t.string "timezone", default: "UTC"
    t.boolean "enable_email_collect", default: true
    t.boolean "csat_survey_enabled", default: false
    t.boolean "allow_messages_after_resolved", default: true
    t.jsonb "auto_assignment_config", default: {}
    t.boolean "lock_to_single_conversation", default: false, null: false
    t.bigint "portal_id"
    t.integer "sender_name_type", default: 0, null: false
    t.string "business_name"
    t.jsonb "csat_config", default: {}, null: false
    t.index ["account_id"], name: "index_inboxes_on_account_id"
    t.index ["channel_id", "channel_type"], name: "index_inboxes_on_channel_id_and_channel_type"
    t.index ["portal_id"], name: "index_inboxes_on_portal_id"
  end

  create_table "installation_configs", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "serialized_value", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "locked", default: true, null: false
    t.index ["name", "created_at"], name: "index_installation_configs_on_name_and_created_at", unique: true
    t.index ["name"], name: "index_installation_configs_on_name", unique: true
  end

  create_table "integrations_hooks", force: :cascade do |t|
    t.integer "status", default: 1
    t.integer "inbox_id"
    t.integer "account_id"
    t.string "app_id"
    t.integer "hook_type", default: 0
    t.string "reference_id"
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "settings", default: {}
  end

  create_table "labels", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "color", default: "#1f93ff", null: false
    t.boolean "show_on_sidebar"
    t.bigint "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_labels_on_account_id"
    t.index ["title", "account_id"], name: "index_labels_on_title_and_account_id", unique: true
  end

  create_table "leaves", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "leave_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "reason"
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status"], name: "index_leaves_on_account_id_and_status"
    t.index ["account_id"], name: "index_leaves_on_account_id"
    t.index ["approved_by_id"], name: "index_leaves_on_approved_by_id"
    t.index ["user_id"], name: "index_leaves_on_user_id"
  end

  create_table "macros", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.integer "visibility", default: 0
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.jsonb "actions", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_macros_on_account_id"
  end

  create_table "mentions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "account_id", null: false
    t.datetime "mentioned_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_mentions_on_account_id"
    t.index ["conversation_id"], name: "index_mentions_on_conversation_id"
    t.index ["user_id", "conversation_id"], name: "index_mentions_on_user_id_and_conversation_id", unique: true
    t.index ["user_id"], name: "index_mentions_on_user_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.text "content"
    t.integer "account_id", null: false
    t.integer "inbox_id", null: false
    t.integer "conversation_id", null: false
    t.integer "message_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "private", default: false, null: false
    t.integer "status", default: 0
    t.text "source_id"
    t.integer "content_type", default: 0, null: false
    t.json "content_attributes", default: {}
    t.string "sender_type"
    t.bigint "sender_id"
    t.jsonb "external_source_ids", default: {}
    t.jsonb "additional_attributes", default: {}
    t.text "processed_message_content"
    t.jsonb "sentiment", default: {}
    t.index "((additional_attributes -> 'campaign_id'::text))", name: "index_messages_on_additional_attributes_campaign_id", using: :gin
    t.index ["account_id", "content_type", "created_at"], name: "idx_messages_account_content_created"
    t.index ["account_id", "created_at", "message_type"], name: "index_messages_on_account_created_type"
    t.index ["account_id", "inbox_id"], name: "index_messages_on_account_id_and_inbox_id"
    t.index ["account_id"], name: "index_messages_on_account_id"
    t.index ["content"], name: "index_messages_on_content", opclass: :gin_trgm_ops, using: :gin
    t.index ["conversation_id", "account_id", "message_type", "created_at"], name: "index_messages_on_conversation_account_type_created"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["inbox_id"], name: "index_messages_on_inbox_id"
    t.index ["sender_type", "sender_id"], name: "index_messages_on_sender_type_and_sender_id"
    t.index ["source_id"], name: "index_messages_on_source_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "account_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_notes_on_account_id"
    t.index ["contact_id"], name: "index_notes_on_contact_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.integer "account_id"
    t.integer "user_id"
    t.integer "email_flags", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "push_flags", default: 0, null: false
    t.index ["account_id", "user_id"], name: "by_account_user", unique: true
  end

  create_table "notification_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "subscription_type", null: false
    t.jsonb "subscription_attributes", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "identifier"
    t.index ["identifier"], name: "index_notification_subscriptions_on_identifier", unique: true
    t.index ["user_id"], name: "index_notification_subscriptions_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.integer "notification_type", null: false
    t.string "primary_actor_type", null: false
    t.bigint "primary_actor_id", null: false
    t.string "secondary_actor_type"
    t.bigint "secondary_actor_id"
    t.datetime "read_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "snoozed_until"
    t.datetime "last_activity_at", default: -> { "CURRENT_TIMESTAMP" }
    t.jsonb "meta", default: {}
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["last_activity_at"], name: "index_notifications_on_last_activity_at"
    t.index ["primary_actor_type", "primary_actor_id"], name: "uniq_primary_actor_per_account_notifications"
    t.index ["secondary_actor_type", "secondary_actor_id"], name: "uniq_secondary_actor_per_account_notifications"
    t.index ["user_id", "account_id", "snoozed_until", "read_at"], name: "idx_notifications_performance"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "platform_app_permissibles", force: :cascade do |t|
    t.bigint "platform_app_id", null: false
    t.string "permissible_type", null: false
    t.bigint "permissible_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["permissible_type", "permissible_id"], name: "index_platform_app_permissibles_on_permissibles"
    t.index ["platform_app_id", "permissible_id", "permissible_type"], name: "unique_permissibles_index", unique: true
    t.index ["platform_app_id"], name: "index_platform_app_permissibles_on_platform_app_id"
  end

  create_table "platform_apps", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "platform_banners", force: :cascade do |t|
    t.text "banner_message", null: false
    t.integer "banner_type", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "portals", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "custom_domain"
    t.string "color"
    t.string "homepage_link"
    t.string "page_title"
    t.text "header_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "config", default: {"allowed_locales" => ["en"]}
    t.boolean "archived", default: false
    t.bigint "channel_web_widget_id"
    t.jsonb "ssl_settings", default: {}, null: false
    t.index ["channel_web_widget_id"], name: "index_portals_on_channel_web_widget_id"
    t.index ["custom_domain"], name: "index_portals_on_custom_domain", unique: true
    t.index ["slug"], name: "index_portals_on_slug", unique: true
  end

  create_table "portals_members", id: false, force: :cascade do |t|
    t.bigint "portal_id", null: false
    t.bigint "user_id", null: false
    t.index ["portal_id", "user_id"], name: "index_portals_members_on_portal_id_and_user_id", unique: true
    t.index ["portal_id"], name: "index_portals_members_on_portal_id"
    t.index ["user_id"], name: "index_portals_members_on_user_id"
  end

  create_table "related_categories", force: :cascade do |t|
    t.bigint "category_id"
    t.bigint "related_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "related_category_id"], name: "index_related_categories_on_category_id_and_related_category_id", unique: true
    t.index ["related_category_id", "category_id"], name: "index_related_categories_on_related_category_id_and_category_id", unique: true
  end

  create_table "reporting_events", force: :cascade do |t|
    t.string "name"
    t.float "value"
    t.integer "account_id"
    t.integer "inbox_id"
    t.integer "user_id"
    t.integer "conversation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "value_in_business_hours"
    t.datetime "event_start_time", precision: nil
    t.datetime "event_end_time", precision: nil
    t.index ["account_id", "name", "created_at"], name: "reporting_events__account_id__name__created_at"
    t.index ["account_id", "name", "inbox_id", "created_at"], name: "index_reporting_events_for_response_distribution"
    t.index ["account_id"], name: "index_reporting_events_on_account_id"
    t.index ["conversation_id"], name: "index_reporting_events_on_conversation_id"
    t.index ["created_at"], name: "index_reporting_events_on_created_at"
    t.index ["inbox_id"], name: "index_reporting_events_on_inbox_id"
    t.index ["name"], name: "index_reporting_events_on_name"
    t.index ["user_id"], name: "index_reporting_events_on_user_id"
  end

  create_table "reporting_events_rollups", force: :cascade do |t|
    t.integer "account_id", null: false
    t.date "date", null: false
    t.string "dimension_type", null: false
    t.bigint "dimension_id", null: false
    t.string "metric", null: false
    t.bigint "count", default: 0, null: false
    t.float "sum_value", default: 0.0, null: false
    t.float "sum_value_business_hours", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "date", "dimension_type", "dimension_id", "metric"], name: "index_rollup_unique_key", unique: true
    t.index ["account_id", "dimension_type", "date"], name: "index_rollup_summary"
    t.index ["account_id", "metric", "date"], name: "index_rollup_timeseries"
  end

  create_table "sla_events", force: :cascade do |t|
    t.bigint "applied_sla_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "account_id", null: false
    t.bigint "sla_policy_id", null: false
    t.bigint "inbox_id", null: false
    t.integer "event_type"
    t.jsonb "meta", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_sla_events_on_account_id"
    t.index ["applied_sla_id"], name: "index_sla_events_on_applied_sla_id"
    t.index ["conversation_id"], name: "index_sla_events_on_conversation_id"
    t.index ["inbox_id"], name: "index_sla_events_on_inbox_id"
    t.index ["sla_policy_id"], name: "index_sla_events_on_sla_policy_id"
  end

  create_table "sla_policies", force: :cascade do |t|
    t.string "name", null: false
    t.float "first_response_time_threshold"
    t.float "next_response_time_threshold"
    t.boolean "only_during_business_hours", default: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.float "resolution_time_threshold"
    t.boolean "exclude_groups", default: true, null: false
    t.boolean "ai_skip_natural_pause", default: true, null: false
    t.jsonb "auto_apply", default: {}, null: false
    t.index ["account_id"], name: "index_sla_policies_on_account_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index "lower((name)::text) gin_trgm_ops", name: "tags_name_trgm_idx", using: :gin
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "team_members", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_team_members_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_members_on_team_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "allow_auto_assign", default: true
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_teams_on_account_id"
    t.index ["name", "account_id"], name: "index_teams_on_name_and_account_id", unique: true
  end

  create_table "user_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "client_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.string "browser_name"
    t.string "browser_version"
    t.string "device_name"
    t.string "platform_name"
    t.string "platform_version"
    t.string "city"
    t.string "country"
    t.string "country_code"
    t.datetime "last_activity_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "client_id"], name: "index_user_sessions_on_user_id_and_client_id", unique: true
    t.index ["user_id"], name: "index_user_sessions_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "name", null: false
    t.string "display_name"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "pubsub_token"
    t.integer "availability", default: 0
    t.jsonb "ui_settings", default: {}
    t.jsonb "custom_attributes", default: {}
    t.string "type"
    t.text "message_signature"
    t.string "otp_secret"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false, null: false
    t.text "otp_backup_codes"
    t.index ["email"], name: "index_users_on_email"
    t.index ["otp_required_for_login"], name: "index_users_on_otp_required_for_login"
    t.index ["otp_secret"], name: "index_users_on_otp_secret", unique: true
    t.index ["pubsub_token"], name: "index_users_on_pubsub_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.integer "account_id"
    t.integer "inbox_id"
    t.text "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "webhook_type", default: 0
    t.jsonb "subscriptions", default: ["conversation_status_changed", "conversation_updated", "conversation_created", "contact_created", "contact_updated", "message_created", "message_updated", "webwidget_triggered"]
    t.string "name"
    t.string "secret"
    t.boolean "include_contact_pii", default: false, null: false
    t.index ["account_id", "url"], name: "index_webhooks_on_account_id_and_url", unique: true
  end

  create_table "whatsapp_api_campaign_recipients", force: :cascade do |t|
    t.bigint "whatsapp_api_campaign_id", null: false
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "conversation_id"
    t.bigint "message_id"
    t.integer "status", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.string "phone_mask"
    t.string "phone_hash"
    t.string "rendered_body_sha256"
    t.string "provider_message_id"
    t.text "last_error_message"
    t.datetime "started_at"
    t.datetime "sent_at"
    t.datetime "failed_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_whatsapp_api_campaign_recipients_on_account_id"
    t.index ["contact_id"], name: "index_whatsapp_api_campaign_recipients_on_contact_id"
    t.index ["conversation_id"], name: "index_whatsapp_api_campaign_recipients_on_conversation_id"
    t.index ["inbox_id", "status", "created_at"], name: "idx_wa_api_recipients_inbox_status"
    t.index ["inbox_id"], name: "index_whatsapp_api_campaign_recipients_on_inbox_id"
    t.index ["message_id"], name: "index_whatsapp_api_campaign_recipients_on_message_id"
    t.index ["whatsapp_api_campaign_id", "contact_id"], name: "idx_wa_api_recipients_campaign_contact", unique: true
    t.index ["whatsapp_api_campaign_id", "message_id"], name: "idx_wa_api_recipients_campaign_message", unique: true, where: "(message_id IS NOT NULL)"
    t.index ["whatsapp_api_campaign_id", "phone_hash"], name: "idx_wa_api_recipients_active_phone_hash", unique: true, where: "((phone_hash IS NOT NULL) AND (status = ANY (ARRAY[0, 1, 2])))"
    t.index ["whatsapp_api_campaign_id", "status"], name: "idx_wa_api_recipients_campaign_status"
    t.index ["whatsapp_api_campaign_id"], name: "idx_wa_api_recipients_campaign_id"
  end

  create_table "whatsapp_api_campaigns", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "created_by_id", null: false
    t.bigint "whatsapp_api_message_template_id"
    t.string "title", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "audience", default: [], null: false
    t.text "message_body"
    t.jsonb "template_snapshot", default: {}, null: false
    t.jsonb "media_snapshot", default: {}, null: false
    t.integer "recipients_count", default: 0, null: false
    t.integer "sent_count", default: 0, null: false
    t.integer "failed_count", default: 0, null: false
    t.integer "cancelled_count", default: 0, null: false
    t.text "last_error_message"
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "paused_at"
    t.datetime "resumed_at"
    t.datetime "completed_at"
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "status", "scheduled_at"], name: "idx_whatsapp_api_campaigns_account_status"
    t.index ["account_id"], name: "index_whatsapp_api_campaigns_on_account_id"
    t.index ["created_by_id"], name: "index_whatsapp_api_campaigns_on_created_by_id"
    t.index ["inbox_id", "status", "scheduled_at"], name: "idx_whatsapp_api_campaigns_inbox_status"
    t.index ["inbox_id"], name: "index_whatsapp_api_campaigns_on_inbox_id"
    t.index ["whatsapp_api_message_template_id"], name: "idx_whatsapp_api_campaigns_template_id"
  end

  create_table "whatsapp_api_message_templates", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "inbox_id", null: false
    t.bigint "created_by_id", null: false
    t.bigint "updated_by_id"
    t.string "name", null: false
    t.text "body", null: false
    t.jsonb "variables", default: [], null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "inbox_id", "archived_at"], name: "idx_whatsapp_api_templates_inbox"
    t.index ["account_id", "inbox_id", "name"], name: "idx_whatsapp_api_templates_active_name", unique: true, where: "(archived_at IS NULL)"
    t.index ["account_id"], name: "index_whatsapp_api_message_templates_on_account_id"
    t.index ["created_by_id"], name: "index_whatsapp_api_message_templates_on_created_by_id"
    t.index ["inbox_id"], name: "index_whatsapp_api_message_templates_on_inbox_id"
    t.index ["updated_by_id"], name: "index_whatsapp_api_message_templates_on_updated_by_id"
  end

  create_table "working_hours", force: :cascade do |t|
    t.bigint "inbox_id"
    t.bigint "account_id"
    t.integer "day_of_week", null: false
    t.boolean "closed_all_day", default: false
    t.integer "open_hour"
    t.integer "open_minutes"
    t.integer "close_hour"
    t.integer "close_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "open_all_day", default: false
    t.index ["account_id"], name: "index_working_hours_on_account_id"
    t.index ["inbox_id"], name: "index_working_hours_on_inbox_id"
  end

  add_foreign_key "account_email_oauth_apps", "accounts"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "autonomia_agent_build_threads", "accounts"
  add_foreign_key "autonomia_agent_build_threads", "autonomia_agents"
  add_foreign_key "autonomia_agent_build_threads", "users", column: "created_by_id"
  add_foreign_key "autonomia_agent_events", "accounts"
  add_foreign_key "autonomia_agent_events", "autonomia_agents"
  add_foreign_key "autonomia_agent_inboxes", "accounts"
  add_foreign_key "autonomia_agent_inboxes", "agent_bots"
  add_foreign_key "autonomia_agent_inboxes", "autonomia_agents"
  add_foreign_key "autonomia_agent_inboxes", "inboxes"
  add_foreign_key "autonomia_agent_instruction_versions", "accounts"
  add_foreign_key "autonomia_agent_instruction_versions", "autonomia_agents", on_delete: :cascade
  add_foreign_key "autonomia_agent_instruction_versions", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "autonomia_agent_knowledge", "accounts"
  add_foreign_key "autonomia_agent_knowledge", "autonomia_agents"
  add_foreign_key "autonomia_agent_sources", "accounts"
  add_foreign_key "autonomia_agent_sources", "autonomia_agents"
  add_foreign_key "autonomia_agents", "accounts"
  add_foreign_key "autonomia_agents", "users", column: "created_by_id"
  add_foreign_key "autonomia_prospecting_leads", "accounts", on_delete: :cascade
  add_foreign_key "autonomia_prospecting_leads", "autonomia_prospecting_searches", column: "prospect_search_id", on_delete: :nullify
  add_foreign_key "autonomia_prospecting_leads", "contacts", on_delete: :nullify
  add_foreign_key "autonomia_prospecting_leads", "crm_cards", on_delete: :nullify
  add_foreign_key "autonomia_prospecting_list_leads", "accounts", on_delete: :cascade
  add_foreign_key "autonomia_prospecting_list_leads", "autonomia_prospecting_leads", column: "prospect_lead_id", on_delete: :cascade
  add_foreign_key "autonomia_prospecting_list_leads", "autonomia_prospecting_lists", column: "prospect_list_id", on_delete: :cascade
  add_foreign_key "autonomia_prospecting_lists", "accounts", on_delete: :cascade
  add_foreign_key "autonomia_prospecting_lists", "users", on_delete: :nullify
  add_foreign_key "autonomia_prospecting_searches", "accounts", on_delete: :cascade
  add_foreign_key "autonomia_prospecting_searches", "users", on_delete: :nullify
  add_foreign_key "autonomia_prospecting_settings", "accounts", on_delete: :cascade
  add_foreign_key "autonomia_prospecting_settings", "crm_pipeline_stages", column: "default_crm_stage_id", on_delete: :nullify
  add_foreign_key "autonomia_prospecting_settings", "crm_pipelines", column: "default_crm_pipeline_id", on_delete: :nullify
  add_foreign_key "crm_activities", "accounts"
  add_foreign_key "crm_activities", "conversations"
  add_foreign_key "crm_activities", "crm_cards", column: "card_id"
  add_foreign_key "crm_agent_booking_links", "accounts"
  add_foreign_key "crm_agent_booking_links", "crm_agent_booking_profiles", column: "booking_profile_id"
  add_foreign_key "crm_agent_booking_links", "inboxes"
  add_foreign_key "crm_agent_booking_links", "users", column: "agent_id"
  add_foreign_key "crm_agent_booking_profiles", "accounts"
  add_foreign_key "crm_agent_booking_profiles", "inboxes"
  add_foreign_key "crm_ai_stage_suggestions", "accounts"
  add_foreign_key "crm_ai_stage_suggestions", "crm_cards", column: "card_id"
  add_foreign_key "crm_ai_stage_suggestions", "crm_pipeline_stages", column: "from_stage_id"
  add_foreign_key "crm_ai_stage_suggestions", "crm_pipeline_stages", column: "to_stage_id"
  add_foreign_key "crm_calendar_sync_states", "accounts"
  add_foreign_key "crm_calendar_sync_states", "inboxes"
  add_foreign_key "crm_card_conversations", "accounts"
  add_foreign_key "crm_card_conversations", "conversations", on_delete: :cascade
  add_foreign_key "crm_card_conversations", "crm_cards", column: "card_id"
  add_foreign_key "crm_card_conversations", "users", column: "linked_by_id"
  add_foreign_key "crm_cards", "accounts"
  add_foreign_key "crm_cards", "contacts"
  add_foreign_key "crm_cards", "conversations"
  add_foreign_key "crm_cards", "crm_pipeline_stages", column: "stage_id"
  add_foreign_key "crm_cards", "crm_pipelines", column: "pipeline_id"
  add_foreign_key "crm_cards", "inboxes"
  add_foreign_key "crm_cards", "teams"
  add_foreign_key "crm_cards", "users", column: "owner_id"
  add_foreign_key "crm_follow_ups", "accounts"
  add_foreign_key "crm_follow_ups", "contacts"
  add_foreign_key "crm_follow_ups", "conversations"
  add_foreign_key "crm_follow_ups", "crm_cards", column: "card_id"
  add_foreign_key "crm_follow_ups", "inboxes"
  add_foreign_key "crm_follow_ups", "users", column: "assignee_id"
  add_foreign_key "crm_follow_ups", "users", column: "created_by_id"
  add_foreign_key "crm_inbox_settings", "accounts"
  add_foreign_key "crm_inbox_settings", "crm_pipeline_stages", column: "default_stage_id"
  add_foreign_key "crm_inbox_settings", "crm_pipelines", column: "default_pipeline_id"
  add_foreign_key "crm_inbox_settings", "inboxes"
  add_foreign_key "crm_integration_tokens", "account_users", on_delete: :nullify
  add_foreign_key "crm_integration_tokens", "accounts"
  add_foreign_key "crm_integration_tokens", "custom_roles", on_delete: :nullify
  add_foreign_key "crm_integration_tokens", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "crm_meeting_guests", "accounts"
  add_foreign_key "crm_meeting_guests", "contacts"
  add_foreign_key "crm_meeting_guests", "crm_meetings", column: "meeting_id"
  add_foreign_key "crm_meeting_guests", "users"
  add_foreign_key "crm_meetings", "accounts"
  add_foreign_key "crm_meetings", "crm_cards", column: "card_id"
  add_foreign_key "crm_meetings", "crm_follow_ups", column: "reminder_id", on_delete: :nullify
  add_foreign_key "crm_meetings", "inboxes", on_delete: :nullify
  add_foreign_key "crm_meetings", "users", column: "created_by_id"
  add_foreign_key "crm_pipeline_inboxes", "accounts"
  add_foreign_key "crm_pipeline_inboxes", "crm_pipeline_stages", column: "default_stage_id"
  add_foreign_key "crm_pipeline_inboxes", "crm_pipelines", column: "pipeline_id"
  add_foreign_key "crm_pipeline_inboxes", "inboxes"
  add_foreign_key "crm_pipeline_inboxes", "users", column: "created_by_id"
  add_foreign_key "crm_pipeline_stages", "accounts"
  add_foreign_key "crm_pipeline_stages", "crm_pipelines", column: "pipeline_id"
  add_foreign_key "crm_pipelines", "accounts"
  add_foreign_key "crm_pipelines", "users", column: "created_by_id"
  add_foreign_key "crm_saved_views", "accounts"
  add_foreign_key "crm_saved_views", "crm_pipelines", column: "pipeline_id"
  add_foreign_key "crm_saved_views", "users"
  add_foreign_key "crm_stage_automation_executions", "accounts"
  add_foreign_key "crm_stage_automation_executions", "crm_cards", column: "card_id"
  add_foreign_key "crm_stage_automation_executions", "crm_stage_automations", column: "stage_automation_id"
  add_foreign_key "crm_stage_automation_steps", "accounts"
  add_foreign_key "crm_stage_automation_steps", "crm_stage_automations", column: "stage_automation_id"
  add_foreign_key "crm_stage_automations", "accounts"
  add_foreign_key "crm_stage_automations", "crm_pipeline_stages", column: "stage_id"
  add_foreign_key "crm_stage_automations", "crm_pipelines", column: "pipeline_id"
  add_foreign_key "crm_stage_automations", "users", column: "created_by_id"
  add_foreign_key "email_campaign_recipients", "email_campaigns"
  add_foreign_key "email_campaign_templates", "accounts"
  add_foreign_key "email_campaigns", "accounts"
  add_foreign_key "email_campaigns", "email_sender_identities", column: "sender_identity_id"
  add_foreign_key "email_campaigns", "inboxes", column: "sender_inbox_id"
  add_foreign_key "email_events", "email_campaign_recipients", column: "recipient_id"
  add_foreign_key "email_sender_identities", "accounts"
  add_foreign_key "email_suppressions", "accounts"
  add_foreign_key "idempotency_keys", "accounts"
  add_foreign_key "inboxes", "portals"
  add_foreign_key "user_sessions", "users"
  add_foreign_key "whatsapp_api_campaign_recipients", "accounts"
  add_foreign_key "whatsapp_api_campaign_recipients", "contacts"
  add_foreign_key "whatsapp_api_campaign_recipients", "conversations"
  add_foreign_key "whatsapp_api_campaign_recipients", "inboxes"
  add_foreign_key "whatsapp_api_campaign_recipients", "messages"
  add_foreign_key "whatsapp_api_campaign_recipients", "whatsapp_api_campaigns"
  add_foreign_key "whatsapp_api_campaigns", "accounts"
  add_foreign_key "whatsapp_api_campaigns", "inboxes"
  add_foreign_key "whatsapp_api_campaigns", "users", column: "created_by_id"
  add_foreign_key "whatsapp_api_campaigns", "whatsapp_api_message_templates"
  add_foreign_key "whatsapp_api_message_templates", "accounts"
  add_foreign_key "whatsapp_api_message_templates", "inboxes"
  add_foreign_key "whatsapp_api_message_templates", "users", column: "created_by_id"
  add_foreign_key "whatsapp_api_message_templates", "users", column: "updated_by_id"
  create_trigger("accounts_after_insert_row_tr", :generated => true, :compatibility => 1).
      on("accounts").
      after(:insert).
      for_each(:row) do
    "execute format('create sequence IF NOT EXISTS conv_dpid_seq_%s', NEW.id);"
  end

  create_trigger("conversations_before_insert_row_tr", :generated => true, :compatibility => 1).
      on("conversations").
      before(:insert).
      for_each(:row) do
    "NEW.display_id := nextval('conv_dpid_seq_' || NEW.account_id);"
  end

  create_trigger("camp_dpid_before_insert", :generated => true, :compatibility => 1).
      on("accounts").
      name("camp_dpid_before_insert").
      after(:insert).
      for_each(:row) do
    "execute format('create sequence IF NOT EXISTS camp_dpid_seq_%s', NEW.id);"
  end

  create_trigger("campaigns_before_insert_row_tr", :generated => true, :compatibility => 1).
      on("campaigns").
      before(:insert).
      for_each(:row) do
    "NEW.display_id := nextval('camp_dpid_seq_' || NEW.account_id);"
  end

end
