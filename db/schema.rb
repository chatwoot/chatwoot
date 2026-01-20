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

ActiveRecord::Schema[7.1].define(version: 2026_01_16_100001) do
  create_schema "auth"
  create_schema "chatwoot"
  create_schema "evolution"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"

  # These extensions should be enabled to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"
  enable_extension "vector"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "public.DeviceMessage", ["ios", "android", "web", "unknown", "desktop"]
  create_enum "public.DifyBotType", ["chatBot", "textGenerator", "agent", "workflow"]
  create_enum "public.InstanceConnectionStatus", ["open", "close", "connecting"]
  create_enum "public.OpenaiBotType", ["assistant", "chatCompletion"]
  create_enum "public.SessionStatus", ["opened", "closed", "paused"]
  create_enum "public.TriggerOperator", ["contains", "equals", "startsWith", "endsWith", "regex"]
  create_enum "public.TriggerType", ["all", "keyword", "none", "advanced"]

  create_table "access_tokens", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.text "access_permissions", default: [], array: true
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
  end

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
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
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
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
  end

  create_table "agent_capacity_policies", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", limit: 255, null: false
    t.text "description"
    t.jsonb "exclusion_rules", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ai_assistant_thread", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.string "thread_id", null: false
    t.uuid "system_user_id", null: false
    t.uuid "product_id"
    t.timestamptz "last_activity", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.string "assistant_id", limit: 255
  end

  create_table "ai_assistants", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "product_id"
    t.string "assistant_id", null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.text "vector_store_id"
  end

  create_table "applied_slas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "sla_policy_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sla_status", default: 0
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
  end

  create_table "campaign_delivery_reports", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.string "provider"
    t.string "status", default: "pending", null: false
    t.integer "total", default: 0, null: false
    t.integer "succeeded", default: 0, null: false
    t.integer "failed", default: 0, null: false
    t.jsonb "delivery_errors", default: [], null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "campaign_message_mappings", force: :cascade do |t|
    t.bigint "campaign_delivery_report_id", null: false
    t.bigint "contact_id", null: false
    t.string "whatsapp_message_id", null: false
    t.string "status", default: "sent", null: false
    t.string "error_code"
    t.string "error_message"
    t.text "error_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "canned_responses", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "short_code"
    t.text "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
  end

  create_table "captain_documents", force: :cascade do |t|
    t.string "name"
    t.string "external_link", null: false
    t.text "content"
    t.bigint "assistant_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "metadata", default: {}
  end

  create_table "captain_inboxes", force: :cascade do |t|
    t.bigint "captain_assistant_id", null: false
    t.bigint "inbox_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "channel_facebook_pages", id: :serial, force: :cascade do |t|
    t.string "page_id", null: false
    t.string "user_access_token", null: false
    t.string "page_access_token", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "instagram_id"
  end

  create_table "channel_instagram", force: :cascade do |t|
    t.string "access_token", null: false
    t.datetime "expires_at", null: false
    t.integer "account_id", null: false
    t.string "instagram_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "channel_line", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "line_channel_id", null: false
    t.string "line_channel_secret", null: false
    t.string "line_channel_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "channel_sms", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "channel_telegram", force: :cascade do |t|
    t.string "bot_name"
    t.integer "account_id", null: false
    t.string "bot_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "channel_twitter_profiles", force: :cascade do |t|
    t.string "profile_id", null: false
    t.string "twitter_access_token", null: false
    t.string "twitter_access_token_secret", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "tweets_enabled", default: true
  end

  create_table "channel_voice", force: :cascade do |t|
    t.string "phone_number", null: false
    t.string "provider", default: "twilio", null: false
    t.jsonb "provider_config", null: false
    t.integer "account_id", null: false
    t.jsonb "additional_attributes", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "domain"
    t.text "description"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "contacts_count", default: 0, null: false
  end

  create_table "company_campaign_items", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "company_campaign_id", null: false
    t.uuid "product_id", null: false
    t.string "company_erp_id", limit: 50, null: false
    t.string "product_erp_id", limit: 50, null: false
    t.integer "sequence_number", null: false
    t.decimal "promotion_price", precision: 10, scale: 2
    t.decimal "min_quantity", precision: 10, scale: 3, default: "0.0"
    t.decimal "max_quantity", precision: 10, scale: 3, default: "0.0"
    t.boolean "is_active", default: true
    t.timestamptz "last_update"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.jsonb "data_json"
  end

  create_table "company_campaign_medias", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "company_campaign_id"
    t.text "media_url", null: false
    t.string "media_type", limit: 10
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "company_campaigns", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.string "company_erp_id", limit: 20
    t.uuid "company_store_id"
    t.string "campaign_name", limit: 60, null: false
    t.string "campaign_type", limit: 1
    t.string "system_price_type", limit: 1
    t.integer "system_promo_type"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "last_update", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.boolean "is_active", default: true
    t.decimal "min_purchase_value", precision: 15, scale: 2
    t.boolean "apply_other_items", default: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.uuid "system_company_id", null: false
    t.jsonb "data_json"
    t.check_constraint "campaign_type = ANY (ARRAY['P'::bpchar, 'M'::bpchar])", name: "company_campaigns_campaign_type_check"
    t.check_constraint "system_price_type = ANY (ARRAY['N'::bpchar, 'L'::bpchar, 'C'::bpchar, 'A'::bpchar])", name: "company_campaigns_system_price_type_check"
  end

  create_table "company_invoice_items", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "company_invoice_id"
    t.uuid "product_id"
    t.string "company_erp_id", limit: 20
    t.string "product_erp_id", limit: 20
    t.string "sub_product_erp_id", limit: 20
    t.integer "sequence_number"
    t.decimal "discount_value", precision: 15, scale: 6
    t.decimal "additional_value", precision: 15, scale: 6
    t.decimal "tax_value", precision: 15, scale: 6
    t.decimal "shipping_value", precision: 15, scale: 6
    t.decimal "quantity", precision: 12, scale: 3
    t.decimal "unit_price", precision: 15, scale: 6
    t.decimal "total_price", precision: 15, scale: 6
    t.string "product_description", limit: 60
    t.string "fiscal_operation_id", limit: 20
    t.string "fiscal_operation_description", limit: 40
    t.string "cfop_code", limit: 10
    t.string "movement_date", limit: 30
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.jsonb "data_json"
  end

  create_table "company_invoices", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.string "company_erp_id", limit: 20
    t.uuid "company_store_id"
    t.uuid "company_client_id"
    t.uuid "company_seller_id"
    t.integer "invoice_number"
    t.string "invoice_series", limit: 3
    t.string "invoice_model", limit: 3
    t.string "invoice_type", limit: 1
    t.string "invoice_status", limit: 1
    t.decimal "total_value", precision: 14, scale: 2
    t.decimal "discount_value", precision: 15, scale: 6
    t.decimal "additional_value", precision: 15, scale: 6
    t.decimal "tax_value", precision: 15, scale: 6
    t.decimal "shipping_value", precision: 14, scale: 2
    t.decimal "payment_value", precision: 14, scale: 2
    t.string "payment_method_id", limit: 20
    t.string "payment_method_description", limit: 100
    t.string "fiscal_key", limit: 44
    t.string "external_code", limit: 30
    t.string "order_id", limit: 20
    t.string "movement_date", limit: 30
    t.string "issue_date", limit: 30
    t.string "cancellation_date", limit: 30
    t.string "last_update", limit: 30, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.jsonb "data_json"
    t.check_constraint "invoice_status = ANY (ARRAY['T'::bpchar, 'F'::bpchar, 'C'::bpchar])", name: "company_invoices_invoice_status_check"
  end

  create_table "company_partner_embedding", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "partner_id", null: false
    t.vector "embedding", limit: 1536
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "company_partner_tasks", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "owner_user_id", null: false
    t.uuid "target_partner_id"
    t.string "title", limit: 255, null: false
    t.string "type", limit: 50, null: false
    t.text "description", null: false
    t.datetime "due_date", precision: nil, null: false
    t.string "status", limit: 20, default: "pending"
    t.uuid "origin_interaction"
    t.uuid "resulted_interaction"
    t.uuid "origin_invoice"
    t.uuid "resulted_invoice"
    t.uuid "campaign_id"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
  end

  create_table "company_partners", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.string "company_erp_id", limit: 20
    t.string "person_type", limit: 1
    t.string "name", limit: 80, null: false
    t.string "trade_name", limit: 80
    t.string "tax_id", limit: 14
    t.string "identity_number", limit: 15
    t.string "issuing_agency", limit: 10
    t.string "marital_status", limit: 1
    t.date "birth_date"
    t.string "address", limit: 80
    t.string "address_number", limit: 10
    t.string "neighborhood", limit: 40
    t.string "city", limit: 200
    t.integer "postal_code"
    t.string "address_complement", limit: 80
    t.string "state", limit: 2
    t.string "region", limit: 40
    t.text "general_notes"
    t.string "business_phone", limit: 20
    t.string "home_phone", limit: 20
    t.string "fax", limit: 20
    t.string "mobile_phone", limit: 20
    t.string "email", limit: 200
    t.string "municipal_registration", limit: 20
    t.string "state_registration", limit: 20
    t.string "business_activity", limit: 100
    t.string "economic_group", limit: 40
    t.decimal "agreement_limit", precision: 14, scale: 2
    t.decimal "credit_limit", precision: 14, scale: 2
    t.string "federal_tax_regime", limit: 1
    t.string "tax_regime_type", limit: 1
    t.string "gender", limit: 1
    t.string "financial_status", limit: 1
    t.integer "ibge_code"
    t.string "tax_contributor", limit: 1
    t.string "seller_name", limit: 80
    t.jsonb "data_json", default: {}
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.string "registration_type", limit: 1
    t.uuid "company_seller_id"
    t.uuid "system_company_id"
    t.boolean "is_active", default: true, comment: "Flag indicating if the partner is active in CISS system"
    t.check_constraint "gender = ANY (ARRAY['M'::bpchar, 'F'::bpchar])", name: "company_clientes_gender_check"
    t.check_constraint "tax_contributor = ANY (ARRAY['T'::bpchar, 'F'::bpchar])", name: "company_clientes_tax_contributor_check"
  end

  create_table "company_stock", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "product_id", null: false
    t.uuid "company_store_id", null: false
    t.boolean "in_stock"
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "uses_lot_control", default: false, comment: "Indicates if the product uses lot control"
    t.text "lot_description", comment: "Description of the lot/batch"
    t.boolean "allows_negative_stock", default: false, comment: "Indicates if negative stock is allowed"
    t.datetime "last_stock_update", precision: nil, comment: "Timestamp of the last stock update from CISS"
    t.decimal "quantity_available", precision: 15, scale: 3, default: "0.0", null: false
    t.decimal "quantity_reserved", precision: 15, scale: 3, default: "0.0", null: false
    t.decimal "quantity_total", precision: 15, scale: 3, default: "0.0", null: false
    t.string "location", limit: 100
    t.jsonb "data_json"
  end

  create_table "company_stock_retail_price", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "company_stock_id", null: false
    t.decimal "retail_price", precision: 15, scale: 6, null: false
    t.decimal "retail_promotion_price", precision: 15, scale: 6
    t.datetime "retail_promotion_start_date", precision: nil
    t.datetime "retail_promotion_end_date", precision: nil
    t.decimal "wholesale_price", precision: 15, scale: 6
    t.decimal "wholesale_promotion_price", precision: 15, scale: 6
    t.datetime "wholesale_promotion_start_date", precision: nil
    t.datetime "wholesale_promotion_end_date", precision: nil
    t.decimal "replacement_cost", precision: 15, scale: 6
    t.decimal "managerial_cost", precision: 15, scale: 6
    t.decimal "invoice_cost", precision: 15, scale: 6
    t.datetime "retail_price_change_date", precision: nil
    t.datetime "retail_promotion_change_date", precision: nil
    t.datetime "wholesale_price_change_date", precision: nil
    t.datetime "wholesale_promotion_change_date", precision: nil
    t.datetime "price_change_date", precision: nil
    t.boolean "is_inactive", default: false
    t.decimal "sale_multiplier", precision: 12, scale: 3
    t.decimal "retail_price_with_multiplier", precision: 15, scale: 6
    t.string "currency", limit: 3, default: "BRL"
    t.decimal "max_discount_percentage", precision: 5, scale: 2
    t.decimal "max_discount_amount", precision: 15, scale: 2
    t.string "ipi_tax", limit: 10
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "data_json"
  end

  create_table "company_stores", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.string "company_erp_id", limit: 20
    t.uuid "system_company_id"
    t.string "trade_name", limit: 60
    t.string "legal_name", limit: 60
    t.string "tax_id", limit: 14
    t.string "municipal_registration", limit: 20
    t.string "state_registration", limit: 16
    t.string "address", limit: 60
    t.string "address_number", limit: 10
    t.string "neighborhood", limit: 20
    t.string "city", limit: 200
    t.string "state", limit: 2
    t.integer "postal_code"
    t.string "address_complement", limit: 80
    t.string "phone", limit: 20
    t.string "fax", limit: 20
    t.string "email", limit: 40
    t.string "administrator_name", limit: 30
    t.string "accountant_name", limit: 30
    t.string "federal_tax_regime", limit: 1
    t.jsonb "data_json", default: {}
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.check_constraint "federal_tax_regime = ANY (ARRAY['R'::bpchar, 'P'::bpchar, 'S'::bpchar])", name: "company_store_federal_tax_regime_check"
  end

  create_table "company_suppliers", id: false, force: :cascade do |t|
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.uuid "system_company_id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "product_supplier_id", default: -> { "gen_random_uuid()" }, null: false
  end

  create_table "contact_inboxes", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "inbox_id"
    t.text "source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hmac_verified", default: false
    t.string "pubsub_token"
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
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "copilot_messages", force: :cascade do |t|
    t.bigint "copilot_thread_id", null: false
    t.bigint "account_id", null: false
    t.jsonb "message", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "message_type", default: 0
  end

  create_table "copilot_threads", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "user_id", null: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "assistant_id"
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
  end

  create_table "custom_filters", force: :cascade do |t|
    t.string "name", null: false
    t.integer "filter_type", default: 0, null: false
    t.jsonb "query", default: "{}", null: false
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "custom_roles", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.bigint "account_id", null: false
    t.text "permissions", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dashboard_apps", force: :cascade do |t|
    t.string "title", null: false
    t.jsonb "content", default: []
    t.bigint "account_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", null: false
    t.integer "account_id"
    t.integer "template_type", default: 1
    t.integer "locale", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "folders", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "category_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inbox_assignment_policies", force: :cascade do |t|
    t.bigint "inbox_id", null: false
    t.bigint "assignment_policy_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inbox_capacity_limits", force: :cascade do |t|
    t.bigint "agent_capacity_policy_id", null: false
    t.bigint "inbox_id", null: false
    t.integer "conversation_limit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "inbox_members", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inbox_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "inbox_migrations", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "source_inbox_id", null: false
    t.bigint "destination_inbox_id", null: false
    t.bigint "user_id"
    t.integer "status", default: 0, null: false
    t.integer "conversations_count", default: 0
    t.integer "conversations_moved", default: 0
    t.integer "messages_count", default: 0
    t.integer "messages_moved", default: 0
    t.integer "attachments_count", default: 0
    t.integer "attachments_moved", default: 0
    t.integer "contact_inboxes_count", default: 0
    t.integer "contact_inboxes_moved", default: 0
    t.integer "contacts_merged", default: 0
    t.text "error_message"
    t.text "error_backtrace"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_inbox_migrations_on_account_id"
    t.index ["destination_inbox_id"], name: "index_inbox_migrations_on_destination_inbox_id"
    t.index ["source_inbox_id", "status"], name: "index_inbox_migrations_active_source", where: "(status = ANY (ARRAY[0, 1]))"
    t.index ["source_inbox_id"], name: "index_inbox_migrations_on_source_inbox_id"
    t.index ["user_id"], name: "index_inbox_migrations_on_user_id"
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
  end

  create_table "installation_configs", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "serialized_value", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "locked", default: true, null: false
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
  end

  create_table "mentions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "account_id", null: false
    t.datetime "mentioned_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "notes", force: :cascade do |t|
    t.text "content", null: false
    t.bigint "account_id", null: false
    t.bigint "contact_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notification_settings", force: :cascade do |t|
    t.integer "account_id"
    t.integer "user_id"
    t.integer "email_flags", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "push_flags", default: 0, null: false
  end

  create_table "notification_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "subscription_type", null: false
    t.jsonb "subscription_attributes", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "identifier"
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
  end

  create_table "platform_app_permissibles", force: :cascade do |t|
    t.bigint "platform_app_id", null: false
    t.string "permissible_type", null: false
    t.bigint "permissible_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "platform_apps", force: :cascade do |t|
    t.string "name", null: false
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
  end

  create_table "portals_members", id: false, force: :cascade do |t|
    t.bigint "portal_id", null: false
    t.bigint "user_id", null: false
  end

  create_table "product_documents", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "product_id", null: false
    t.text "name", null: false
    t.text "document_url", null: false
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.boolean "is_active", default: true, null: false
  end

  create_table "product_embeddings", id: false, force: :cascade do |t|
    t.vector "embedding", limit: 1536
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.uuid "product_id"
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
  end

  create_table "product_images", id: false, force: :cascade do |t|
    t.text "image_url", null: false
    t.uuid "product_id", default: -> { "gen_random_uuid()" }, null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.boolean "is_active", default: true, null: false
  end

  create_table "product_reviews", id: false, force: :cascade do |t|
    t.decimal "rating", precision: 2, scale: 1
    t.uuid "product_id", default: -> { "gen_random_uuid()" }
    t.uuid "system_user_id", default: -> { "gen_random_uuid()" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "title", limit: 255
    t.text "content"
  end

  create_table "product_specifications", id: false, force: :cascade do |t|
    t.string "material", limit: 255
    t.string "model_number", limit: 50
    t.string "weight", limit: 50
    t.string "color", limit: 50
    t.string "length", limit: 50
    t.string "width", limit: 50
    t.string "height", limit: 50
    t.string "voltage", limit: 50
    t.string "power", limit: 50
    t.string "warranty_period", limit: 50
    t.text "warranty_coverage"
    t.text "certifications"
    t.string "battery_type", limit: 50
    t.string "battery_capacity", limit: 50
    t.string "battery_life", limit: 50
    t.text "software_requirements"
    t.text "network_compatibility"
    t.uuid "product_id", default: -> { "gen_random_uuid()" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.string "entry_packaging", limit: 50
    t.decimal "entry_weight", precision: 15, scale: 6
    t.string "exit_packaging", limit: 50
    t.decimal "exit_weight", precision: 12, scale: 3
    t.decimal "multiplication_quantity", precision: 12, scale: 3
    t.string "sales_packaging_weight", limit: 50
    t.string "division_id", limit: 50
    t.string "division_name", limit: 50
    t.string "section_id", limit: 50
    t.string "section_name", limit: 50
    t.string "subgroup_id", limit: 50
    t.string "subgroup_name", limit: 50
    t.string "gross_weight", limit: 50
    t.string "shipping_weight", limit: 50
    t.string "shipping_length", limit: 50
    t.string "shipping_width", limit: 50
    t.string "shipping_height", limit: 50
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "product_suppliers", id: false, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "website", limit: 255
    t.string "contact_email", limit: 255
    t.string "phone_number", limit: 50
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.text "description"
    t.string "logo_url", limit: 255
    t.string "address_street", limit: 255
    t.string "address_number", limit: 20
    t.string "address_complement", limit: 100
    t.string "address_district", limit: 100
    t.string "address_city", limit: 100
    t.string "address_state", limit: 2
    t.string "address_zip", limit: 10
    t.string "contact_name", limit: 100
    t.string "contact_position", limit: 100
    t.string "secondary_phone", limit: 20
    t.string "tax_id", limit: 20
    t.text "payment_terms"
    t.text "delivery_terms"
    t.decimal "minimum_order_value", precision: 10, scale: 2
    t.integer "average_delivery_time"
    t.boolean "is_active", default: true
    t.string "status", limit: 20, default: "active"
    t.jsonb "integration_settings", default: {"api_key" => nil, "api_url" => nil, "enabled" => false, "last_sync" => nil, "sync_frequency" => "daily"}
    t.jsonb "settings", default: {"theme" => {"accent_color" => "#FF0000", "primary_color" => "#000000", "secondary_color" => "#FFFFFF"}, "notification_preferences" => {"push" => true, "email" => true}}
    t.uuid "system_company_id", null: false
  end

  create_table "products", id: false, force: :cascade do |t|
    t.string "sku", limit: 50
    t.text "name", null: false
    t.text "short_name"
    t.string "category", limit: 100
    t.string "brand", limit: 100
    t.string "manufacturer", limit: 100
    t.text "description"
    t.datetime "created_at", precision: nil, default: -> { "now()" }
    t.datetime "updated_at", precision: nil, default: -> { "now()" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "product_supplier_id"
    t.text "sub_description"
    t.string "box_barcode", limit: 50
    t.string "ncm_code", limit: 10
    t.string "manufacturer_cnpj", limit: 14
    t.string "reference_code", limit: 30
    t.boolean "block_sales", default: false
    t.string "model", limit: 50
    t.boolean "ecommerce_enabled", default: false
    t.string "company_erp_id", limit: 20
    t.uuid "product_image_id"
    t.jsonb "data_json", default: {}
    t.boolean "is_active", default: true, comment: "Flag indicating if the product is active in CISS system"
    t.uuid "system_company_id", null: false
  end

  create_table "queue_product_enhancement", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "product_id", null: false
    t.string "status", limit: 20, default: "pending", null: false
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.integer "max_attempts", default: 3, null: false
    t.text "error_message"
    t.timestamptz "created_at", default: -> { "now()" }
    t.timestamptz "updated_at", default: -> { "now()" }
    t.timestamptz "started_at"
    t.timestamptz "completed_at"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying::text, 'processing'::character varying::text, 'completed'::character varying::text, 'failed'::character varying::text])", name: "queue_product_enhancement_status_check"
  end

  create_table "related_categories", force: :cascade do |t|
    t.bigint "category_id"
    t.bigint "related_category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
  end

  create_table "system_companies", id: false, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.text "logo_url"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.text "description"
    t.string "short_name", limit: 50
    t.string "website_url", limit: 255
    t.string "email", limit: 255
    t.string "phone", limit: 20
    t.string "address_street", limit: 255
    t.string "address_number", limit: 20
    t.string "address_complement", limit: 100
    t.string "address_district", limit: 100
    t.string "address_city", limit: 100
    t.string "address_state", limit: 2
    t.string "address_zip", limit: 10
    t.jsonb "social_media", default: {"twitter" => nil, "facebook" => nil, "linkedin" => nil, "instagram" => nil}
    t.jsonb "business_hours", default: {"friday" => {"open" => "08:00", "close" => "18:00"}, "monday" => {"open" => "08:00", "close" => "18:00"}, "sunday" => nil, "tuesday" => {"open" => "08:00", "close" => "18:00"}, "saturday" => {"open" => "08:00", "close" => "12:00"}, "thursday" => {"open" => "08:00", "close" => "18:00"}, "wednesday" => {"open" => "08:00", "close" => "18:00"}}
    t.jsonb "settings", default: {"theme_color" => "#000000", "notification_preferences" => {"push" => true, "email" => true}}
    t.boolean "is_active", default: true
    t.string "status", limit: 20, default: "active"
    t.string "tax_id", limit: 20
    t.string "company_type", limit: 50
  end

  create_table "system_data_sync_logs", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_company_id"
    t.string "sync_data_identifier", limit: 40
    t.datetime "last_successful_sync", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
  end

  create_table "system_users", id: false, force: :cascade do |t|
    t.string "username", limit: 255, null: false
    t.string "email", limit: 255, null: false
    t.string "role", limit: 50
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_company_id", default: -> { "gen_random_uuid()" }
    t.string "first_name", limit: 50
    t.string "last_name", limit: 50
    t.string "phone", limit: 20
    t.boolean "is_active", default: true
    t.timestamptz "last_login_at"
    t.timestamptz "password_changed_at"
    t.string "avatar_url", limit: 255
    t.jsonb "preferences", default: {}
    t.jsonb "user_metadata", default: {}
    t.uuid "company_partner_id"
    t.uuid "company_store_id", comment: "Reference to the company store this user belongs to"
    t.uuid "auth_id", comment: "Auth ID"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
  end

  create_table "team_members", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "allow_auto_assign", default: true
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_favorite_partners", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_user_id", null: false
    t.uuid "company_partner_id", null: false
    t.timestamptz "favorited_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_favorite_products", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_user_id", null: false
    t.uuid "product_id", null: false
    t.timestamptz "favorited_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_goals", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_user_id", null: false
    t.decimal "year_sale", precision: 15, scale: 2
    t.decimal "month_sale", precision: 15, scale: 2
    t.decimal "week_sale", precision: 15, scale: 2
    t.decimal "day_sale", precision: 15, scale: 2
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_partner_group_members", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "group_id", null: false
    t.uuid "company_partner_id", null: false
    t.timestamptz "added_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_partner_groups", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_user_id", null: false
    t.string "group_name", limit: 100, null: false
    t.timestamptz "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.timestamptz "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_recent_partners", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_user_id", null: false
    t.uuid "company_partner_id", null: false
    t.timestamptz "accessed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_recent_products", id: false, force: :cascade do |t|
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.uuid "system_user_id", null: false
    t.uuid "product_id", null: false
    t.timestamptz "accessed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "user_search_history", id: false, force: :cascade do |t|
    t.text "query", null: false
    t.jsonb "results"
    t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.uuid "system_user_id", default: -> { "gen_random_uuid()" }
    t.uuid "id", default: -> { "gen_random_uuid()" }, null: false
    t.timestamptz "updated_at", default: -> { "now()" }, null: false
    t.boolean "is_favorite", default: false
    t.string "favorite_name", limit: 255
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
    t.boolean "otp_required_for_login", default: false
    t.text "otp_backup_codes"
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
  end

  add_foreign_key "inbox_migrations", "accounts"
  add_foreign_key "inbox_migrations", "inboxes", column: "destination_inbox_id"
  add_foreign_key "inbox_migrations", "inboxes", column: "source_inbox_id"
  add_foreign_key "inbox_migrations", "users"
end
