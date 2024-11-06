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

ActiveRecord::Schema[7.0].define(version: 2024_10_31_224155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "DeviceMessage", ["ios", "android", "web", "unknown", "desktop"]
  create_enum "DifyBotType", ["chatBot", "textGenerator", "agent", "workflow"]
  create_enum "InstanceConnectionStatus", ["open", "close", "connecting"]
  create_enum "OpenaiBotType", ["assistant", "chatCompletion"]
  create_enum "SessionStatus", ["opened", "closed", "paused"]
  create_enum "TriggerOperator", ["contains", "equals", "startsWith", "endsWith", "regex"]
  create_enum "TriggerType", ["all", "keyword", "none", "advanced"]

  create_table "Chat", id: :text, force: :cascade do |t|
    t.string "remoteJid", limit: 100, null: false
    t.jsonb "labels"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil
    t.text "instanceId", null: false
    t.string "name", limit: 100
  end

  create_table "Chatwoot", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: true
    t.string "accountId", limit: 100
    t.string "token", limit: 100
    t.string "url", limit: 500
    t.string "nameInbox", limit: 100
    t.boolean "signMsg", default: false
    t.string "signDelimiter", limit: 100
    t.string "number", limit: 100
    t.boolean "reopenConversation", default: false
    t.boolean "conversationPending", default: false
    t.boolean "mergeBrazilContacts", default: false
    t.boolean "importContacts", default: false
    t.boolean "importMessages", default: false
    t.integer "daysLimitImportMessages"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.string "logo", limit: 500
    t.string "organization", limit: 100
    t.jsonb "ignoreJids"
    t.index ["instanceId"], name: "Chatwoot_instanceId_key", unique: true
  end

  create_table "Contact", id: :text, force: :cascade do |t|
    t.string "remoteJid", limit: 100, null: false
    t.string "pushName", limit: 100
    t.string "profilePicUrl", limit: 500
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil
    t.text "instanceId", null: false
    t.index ["remoteJid", "instanceId"], name: "Contact_remoteJid_instanceId_key", unique: true
  end

  create_table "Dify", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.enum "botType", null: false, enum_type: ""DifyBotType""
    t.string "apiUrl", limit: 255
    t.string "apiKey", limit: 255
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.enum "triggerType", enum_type: ""TriggerType""
    t.enum "triggerOperator", enum_type: ""TriggerOperator""
    t.text "triggerValue"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.string "description", limit: 255
  end

  create_table "DifySetting", id: :text, force: :cascade do |t|
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.string "difyIdFallback", limit: 100
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "DifySetting_instanceId_key", unique: true
  end

  create_table "EvolutionBot", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.string "description", limit: 255
    t.string "apiUrl", limit: 255
    t.string "apiKey", limit: 255
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.enum "triggerType", enum_type: ""TriggerType""
    t.enum "triggerOperator", enum_type: ""TriggerOperator""
    t.text "triggerValue"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
  end

  create_table "EvolutionBotSetting", id: :text, force: :cascade do |t|
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.string "botIdFallback", limit: 100
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "EvolutionBotSetting_instanceId_key", unique: true
  end

  create_table "Flowise", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.string "description", limit: 255
    t.string "apiUrl", limit: 255
    t.string "apiKey", limit: 255
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.enum "triggerType", enum_type: ""TriggerType""
    t.enum "triggerOperator", enum_type: ""TriggerOperator""
    t.text "triggerValue"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
  end

  create_table "FlowiseSetting", id: :text, force: :cascade do |t|
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.string "flowiseIdFallback", limit: 100
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "FlowiseSetting_instanceId_key", unique: true
  end

  create_table "Instance", id: :text, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.enum "connectionStatus", default: "open", null: false, enum_type: ""InstanceConnectionStatus""
    t.string "ownerJid", limit: 100
    t.string "profilePicUrl", limit: 500
    t.string "integration", limit: 100
    t.string "number", limit: 100
    t.string "token", limit: 255
    t.string "clientName", limit: 100
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil
    t.string "profileName", limit: 100
    t.string "businessId", limit: 100
    t.datetime "disconnectionAt", precision: nil
    t.jsonb "disconnectionObject"
    t.integer "disconnectionReasonCode"
    t.index ["name"], name: "Instance_name_key", unique: true
  end

  create_table "IntegrationSession", id: :text, force: :cascade do |t|
    t.string "sessionId", limit: 255, null: false
    t.string "remoteJid", limit: 100, null: false
    t.text "pushName"
    t.enum "status", null: false, enum_type: ""SessionStatus""
    t.boolean "awaitUser", default: false, null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.jsonb "parameters"
    t.jsonb "context"
    t.text "botId"
    t.string "type", limit: 100
  end

  create_table "IsOnWhatsapp", id: :text, force: :cascade do |t|
    t.string "remoteJid", limit: 100, null: false
    t.text "jidOptions", null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updatedAt", precision: nil, null: false
    t.index ["remoteJid"], name: "IsOnWhatsapp_remoteJid_key", unique: true
  end

  create_table "Label", id: :text, force: :cascade do |t|
    t.string "labelId", limit: 100
    t.string "name", limit: 100, null: false
    t.string "color", limit: 100, null: false
    t.string "predefinedId", limit: 100
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.index ["labelId", "instanceId"], name: "Label_labelId_instanceId_key", unique: true
  end

  create_table "Media", id: :text, force: :cascade do |t|
    t.string "fileName", limit: 500, null: false
    t.string "type", limit: 100, null: false
    t.string "mimetype", limit: 100, null: false
    t.date "createdAt", default: -> { "CURRENT_TIMESTAMP" }
    t.text "messageId", null: false
    t.text "instanceId", null: false
    t.index ["fileName"], name: "Media_fileName_key", unique: true
    t.index ["messageId"], name: "Media_messageId_key", unique: true
  end

  create_table "Message", id: :text, force: :cascade do |t|
    t.jsonb "key", null: false
    t.string "pushName", limit: 100
    t.string "participant", limit: 100
    t.string "messageType", limit: 100, null: false
    t.jsonb "message", null: false
    t.jsonb "contextInfo"
    t.enum "source", null: false, enum_type: ""DeviceMessage""
    t.integer "messageTimestamp", null: false
    t.integer "chatwootMessageId"
    t.integer "chatwootInboxId"
    t.integer "chatwootConversationId"
    t.string "chatwootContactInboxSourceId", limit: 100
    t.boolean "chatwootIsRead"
    t.text "instanceId", null: false
    t.string "webhookUrl", limit: 500
    t.text "sessionId"
  end

  create_table "MessageUpdate", id: :text, force: :cascade do |t|
    t.string "keyId", limit: 100, null: false
    t.string "remoteJid", limit: 100, null: false
    t.boolean "fromMe", null: false
    t.string "participant", limit: 100
    t.jsonb "pollUpdates"
    t.string "status", limit: 30, null: false
    t.text "messageId", null: false
    t.text "instanceId", null: false
  end

  create_table "OpenaiBot", id: :text, force: :cascade do |t|
    t.string "assistantId", limit: 255
    t.string "model", limit: 100
    t.jsonb "systemMessages"
    t.jsonb "assistantMessages"
    t.jsonb "userMessages"
    t.integer "maxTokens"
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.enum "triggerType", enum_type: ""TriggerType""
    t.enum "triggerOperator", enum_type: ""TriggerOperator""
    t.text "triggerValue"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "openaiCredsId", null: false
    t.text "instanceId", null: false
    t.boolean "enabled", default: true, null: false
    t.enum "botType", null: false, enum_type: ""OpenaiBotType""
    t.string "description", limit: 255
    t.string "functionUrl", limit: 500
  end

  create_table "OpenaiCreds", id: :text, force: :cascade do |t|
    t.string "apiKey", limit: 255
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.string "name", limit: 255
    t.index ["apiKey"], name: "OpenaiCreds_apiKey_key", unique: true
    t.index ["name"], name: "OpenaiCreds_name_key", unique: true
  end

  create_table "OpenaiSetting", id: :text, force: :cascade do |t|
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "openaiCredsId", null: false
    t.string "openaiIdFallback", limit: 100
    t.text "instanceId", null: false
    t.boolean "speechToText", default: false
    t.index ["instanceId"], name: "OpenaiSetting_instanceId_key", unique: true
    t.index ["openaiCredsId"], name: "OpenaiSetting_openaiCredsId_key", unique: true
  end

  create_table "Proxy", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.string "host", limit: 100, null: false
    t.string "port", limit: 100, null: false
    t.string "protocol", limit: 100, null: false
    t.string "username", limit: 100, null: false
    t.string "password", limit: 100, null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "Proxy_instanceId_key", unique: true
  end

  create_table "Rabbitmq", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.jsonb "events", null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "Rabbitmq_instanceId_key", unique: true
  end

  create_table "Session", id: :text, force: :cascade do |t|
    t.text "sessionId", null: false
    t.text "creds"
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["sessionId"], name: "Session_sessionId_key", unique: true
  end

  create_table "Setting", id: :text, force: :cascade do |t|
    t.boolean "rejectCall", default: false, null: false
    t.string "msgCall", limit: 100
    t.boolean "groupsIgnore", default: false, null: false
    t.boolean "alwaysOnline", default: false, null: false
    t.boolean "readMessages", default: false, null: false
    t.boolean "readStatus", default: false, null: false
    t.boolean "syncFullHistory", default: false, null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "Setting_instanceId_key", unique: true
  end

  create_table "Sqs", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.jsonb "events", null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "Sqs_instanceId_key", unique: true
  end

  create_table "Template", id: :text, force: :cascade do |t|
    t.string "templateId", limit: 255, null: false
    t.string "name", limit: 255, null: false
    t.jsonb "template", null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.string "webhookUrl", limit: 500
    t.index ["name"], name: "Template_name_key", unique: true
    t.index ["templateId"], name: "Template_templateId_key", unique: true
  end

  create_table "Typebot", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: true, null: false
    t.string "url", limit: 500, null: false
    t.string "typebot", limit: 100, null: false
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil
    t.enum "triggerType", enum_type: ""TriggerType""
    t.enum "triggerOperator", enum_type: ""TriggerOperator""
    t.text "triggerValue"
    t.text "instanceId", null: false
    t.integer "debounceTime"
    t.jsonb "ignoreJids"
    t.string "description", limit: 255
  end

  create_table "TypebotSetting", id: :text, force: :cascade do |t|
    t.integer "expire", default: 0
    t.string "keywordFinish", limit: 100
    t.integer "delayMessage"
    t.string "unknownMessage", limit: 100
    t.boolean "listeningFromMe", default: false
    t.boolean "stopBotFromMe", default: false
    t.boolean "keepOpen", default: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.integer "debounceTime"
    t.string "typebotIdFallback", limit: 100
    t.jsonb "ignoreJids"
    t.index ["instanceId"], name: "TypebotSetting_instanceId_key", unique: true
  end

  create_table "Webhook", id: :text, force: :cascade do |t|
    t.string "url", limit: 500, null: false
    t.boolean "enabled", default: true
    t.jsonb "events"
    t.boolean "webhookByEvents", default: false
    t.boolean "webhookBase64", default: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.jsonb "headers"
    t.index ["instanceId"], name: "Webhook_instanceId_key", unique: true
  end

  create_table "Websocket", id: :text, force: :cascade do |t|
    t.boolean "enabled", default: false, null: false
    t.jsonb "events", null: false
    t.datetime "createdAt", precision: nil, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "updatedAt", precision: nil, null: false
    t.text "instanceId", null: false
    t.index ["instanceId"], name: "Websocket_instanceId_key", unique: true
  end

  create_table "_prisma_migrations", id: { type: :string, limit: 36 }, force: :cascade do |t|
    t.string "checksum", limit: 64, null: false
    t.timestamptz "finished_at"
    t.string "migration_name", limit: 255, null: false
    t.text "logs"
    t.timestamptz "rolled_back_at"
    t.timestamptz "started_at", default: -> { "now()" }, null: false
    t.integer "applied_steps_count", default: 0, null: false
  end

  create_table "access_tokens", force: :cascade do |t|
    t.string "owner_type"
    t.bigint "owner_id"
    t.string "token"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["owner_type", "owner_id"], name: "index_access_tokens_on_owner_type_and_owner_id"
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
  end

  create_table "account_users", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "user_id"
    t.integer "role", default: 0
    t.bigint "inviter_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "active_at", precision: nil
    t.integer "availability", default: 0, null: false
    t.boolean "auto_offline", default: true, null: false
    t.bigint "custom_role_id"
    t.index ["account_id", "user_id"], name: "uniq_user_id_per_account_id", unique: true
    t.index ["account_id"], name: "index_account_users_on_account_id"
    t.index ["custom_role_id"], name: "index_account_users_on_custom_role_id"
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
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "account_id"
  end

  create_table "agent_bots", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "outgoing_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "account_id"
    t.integer "bot_type", default: 0
    t.jsonb "bot_config", default: {}
    t.index ["account_id"], name: "index_agent_bots_on_account_id"
  end

  create_table "applied_slas", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "sla_policy_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sla_status", default: 0
    t.index ["account_id", "sla_policy_id", "conversation_id"], name: "index_applied_slas_on_account_sla_policy_conversation", unique: true
    t.index ["account_id"], name: "index_applied_slas_on_account_id"
    t.index ["conversation_id"], name: "index_applied_slas_on_conversation_id"
    t.index ["sla_policy_id"], name: "index_applied_slas_on_sla_policy_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.bigint "author_id"
    t.bigint "associated_article_id"
    t.jsonb "meta", default: {}
    t.string "slug", null: false
    t.integer "position"
    t.string "locale", default: "en", null: false
    t.index ["associated_article_id"], name: "index_articles_on_associated_article_id"
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true, null: false
    t.index ["account_id"], name: "index_automation_rules_on_account_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "campaign_type", default: 0, null: false
    t.integer "campaign_status", default: 0, null: false
    t.jsonb "audience", default: []
    t.datetime "scheduled_at", precision: nil
    t.boolean "trigger_only_during_business_hours", default: false
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

  create_table "categories", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "portal_id", null: false
    t.string "name"
    t.text "description"
    t.integer "position"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "locale", default: "en"
    t.string "slug", null: false
    t.bigint "parent_category_id"
    t.bigint "associated_category_id"
    t.string "icon", default: ""
    t.index ["associated_category_id"], name: "index_categories_on_associated_category_id"
    t.index ["locale", "account_id"], name: "index_categories_on_locale_and_account_id"
    t.index ["locale"], name: "index_categories_on_locale"
    t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
    t.index ["slug", "locale", "portal_id"], name: "index_categories_on_slug_and_locale_and_portal_id", unique: true
  end

  create_table "channel_api", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "webhook_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "identifier"
    t.string "hmac_token"
    t.boolean "hmac_mandatory", default: false
    t.jsonb "additional_attributes", default: {}
    t.index ["hmac_token"], name: "index_channel_api_on_hmac_token", unique: true
    t.index ["identifier"], name: "index_channel_api_on_identifier", unique: true
  end

  create_table "channel_email", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "email", null: false
    t.string "forward_to_email", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.index ["email"], name: "index_channel_email_on_email", unique: true
    t.index ["forward_to_email"], name: "index_channel_email_on_forward_to_email", unique: true
  end

  create_table "channel_evolution", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "webhook_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.string "hmac_token"
    t.string "qr_code"
    t.string "instance_id"
    t.boolean "hmac_mandatory", default: false
    t.jsonb "additional_attributes", default: {}
    t.index ["hmac_token"], name: "index_channel_evolution_on_hmac_token", unique: true
    t.index ["identifier"], name: "index_channel_evolution_on_identifier", unique: true
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

  create_table "channel_line", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "line_channel_id", null: false
    t.string "line_channel_secret", null: false
    t.string "line_channel_token", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["line_channel_id"], name: "index_channel_line_on_line_channel_id", unique: true
  end

  create_table "channel_sms", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["phone_number"], name: "index_channel_sms_on_phone_number", unique: true
  end

  create_table "channel_telegram", force: :cascade do |t|
    t.string "bot_name"
    t.integer "account_id", null: false
    t.string "bot_token", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["bot_token"], name: "index_channel_telegram_on_bot_token", unique: true
  end

  create_table "channel_twilio_sms", force: :cascade do |t|
    t.string "phone_number"
    t.string "auth_token", null: false
    t.string "account_sid", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "medium", default: 0
    t.string "messaging_service_sid"
    t.string "api_key_sid"
    t.index ["account_sid", "phone_number"], name: "index_channel_twilio_sms_on_account_sid_and_phone_number", unique: true
    t.index ["messaging_service_sid"], name: "index_channel_twilio_sms_on_messaging_service_sid", unique: true
    t.index ["phone_number"], name: "index_channel_twilio_sms_on_phone_number", unique: true
  end

  create_table "channel_twitter_profiles", force: :cascade do |t|
    t.string "profile_id", null: false
    t.string "twitter_access_token", null: false
    t.string "twitter_access_token_secret", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.index ["hmac_token"], name: "index_channel_web_widgets_on_hmac_token", unique: true
    t.index ["website_token"], name: "index_channel_web_widgets_on_website_token", unique: true
  end

  create_table "channel_whatsapp", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "phone_number", null: false
    t.string "provider", default: "default"
    t.jsonb "provider_config", default: {}
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "message_templates", default: {}
    t.datetime "message_templates_last_updated", precision: nil
    t.index ["phone_number"], name: "index_channel_whatsapp_on_phone_number", unique: true
  end

  create_table "contact_inboxes", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "inbox_id"
    t.string "source_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.index "lower((email)::text), account_id", name: "index_contacts_on_lower_email_account_id"
    t.index ["account_id", "email", "phone_number", "identifier"], name: "index_contacts_on_nonempty_fields", where: "(((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))"
    t.index ["account_id", "last_activity_at"], name: "index_contacts_on_account_id_and_last_activity_at", order: { last_activity_at: "DESC NULLS LAST" }
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["account_id"], name: "index_resolved_contact_account_id", where: "(((email)::text <> ''::text) OR ((phone_number)::text <> ''::text) OR ((identifier)::text <> ''::text))"
    t.index ["blocked"], name: "index_contacts_on_blocked"
    t.index ["email", "account_id"], name: "uniq_email_per_account_contact", unique: true
    t.index ["identifier", "account_id"], name: "uniq_identifier_per_account_contact", unique: true
    t.index ["name", "email", "phone_number", "identifier"], name: "index_contacts_on_name_email_phone_number_identifier", opclass: :gin_trgm_ops, using: :gin
    t.index ["phone_number", "account_id"], name: "index_contacts_on_phone_number_and_account_id"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.index ["account_id", "display_id"], name: "index_conversations_on_account_id_and_display_id", unique: true
    t.index ["account_id", "id"], name: "index_conversations_on_id_and_account_id"
    t.index ["account_id", "inbox_id", "status", "assignee_id"], name: "conv_acid_inbid_stat_asgnid_idx"
    t.index ["account_id"], name: "index_conversations_on_account_id"
    t.index ["assignee_id", "account_id"], name: "index_conversations_on_assignee_id_and_account_id"
    t.index ["campaign_id"], name: "index_conversations_on_campaign_id"
    t.index ["contact_id"], name: "index_conversations_on_contact_id"
    t.index ["contact_inbox_id"], name: "index_conversations_on_contact_inbox_id"
    t.index ["first_reply_created_at"], name: "index_conversations_on_first_reply_created_at"
    t.index ["inbox_id"], name: "index_conversations_on_inbox_id"
    t.index ["priority"], name: "index_conversations_on_priority"
    t.index ["status", "account_id"], name: "index_conversations_on_status_and_account_id"
    t.index ["status", "priority"], name: "index_conversations_on_status_and_priority"
    t.index ["team_id"], name: "index_conversations_on_team_id"
    t.index ["uuid"], name: "index_conversations_on_uuid", unique: true
    t.index ["waiting_since"], name: "index_conversations_on_waiting_since"
  end

  create_table "csat_survey_responses", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "message_id", null: false
    t.integer "rating", null: false
    t.text "feedback_message"
    t.bigint "contact_id", null: false
    t.bigint "assigned_agent_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_csat_survey_responses_on_account_id"
    t.index ["assigned_agent_id"], name: "index_csat_survey_responses_on_assigned_agent_id"
    t.index ["contact_id"], name: "index_csat_survey_responses_on_contact_id"
    t.index ["conversation_id"], name: "index_csat_survey_responses_on_conversation_id"
    t.index ["message_id"], name: "index_csat_survey_responses_on_message_id", unique: true
  end

  create_table "custom_attribute_definitions", force: :cascade do |t|
    t.string "attribute_display_name"
    t.string "attribute_key"
    t.integer "attribute_display_type", default: 0
    t.integer "default_value"
    t.integer "attribute_model", default: 0
    t.bigint "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_data_imports_on_account_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "body", null: false
    t.integer "account_id"
    t.integer "template_type", default: 1
    t.integer "locale", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name", "account_id"], name: "index_email_templates_on_name_and_account_id", unique: true
  end

  create_table "folders", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "category_id", null: false
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.index ["account_id"], name: "index_inboxes_on_account_id"
    t.index ["channel_id", "channel_type"], name: "index_inboxes_on_channel_id_and_channel_type"
    t.index ["portal_id"], name: "index_inboxes_on_portal_id"
  end

  create_table "installation_configs", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "serialized_value", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "settings", default: {}
  end

  create_table "labels", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "color", default: "#1f93ff", null: false
    t.boolean "show_on_sidebar"
    t.bigint "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_labels_on_account_id"
    t.index ["title", "account_id"], name: "index_labels_on_title_and_account_id", unique: true
  end

  create_table "macros", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.integer "visibility", default: 0
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.jsonb "actions", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_macros_on_account_id"
  end

  create_table "mentions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "conversation_id", null: false
    t.bigint "account_id", null: false
    t.datetime "mentioned_at", precision: nil, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.string "source_id"
    t.integer "content_type", default: 0, null: false
    t.json "content_attributes", default: {}
    t.string "sender_type"
    t.bigint "sender_id"
    t.jsonb "external_source_ids", default: {}
    t.jsonb "additional_attributes", default: {}
    t.text "processed_message_content"
    t.jsonb "sentiment", default: {}
    t.index "((additional_attributes -> 'campaign_id'::text))", name: "index_messages_on_additional_attributes_campaign_id", using: :gin
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_notes_on_account_id"
    t.index ["contact_id"], name: "index_notes_on_contact_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.integer "account_id"
    t.integer "user_id"
    t.integer "email_flags", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "push_flags", default: 0, null: false
    t.index ["account_id", "user_id"], name: "by_account_user", unique: true
  end

  create_table "notification_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "subscription_type", null: false
    t.jsonb "subscription_attributes", default: {}, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "snoozed_until"
    t.datetime "last_activity_at", default: -> { "CURRENT_TIMESTAMP" }
    t.jsonb "meta", default: {}
    t.index ["account_id"], name: "index_notifications_on_account_id"
    t.index ["last_activity_at"], name: "index_notifications_on_last_activity_at"
    t.index ["primary_actor_type", "primary_actor_id"], name: "uniq_primary_actor_per_account_notifications"
    t.index ["secondary_actor_type", "secondary_actor_id"], name: "uniq_secondary_actor_per_account_notifications"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "platform_app_permissibles", force: :cascade do |t|
    t.bigint "platform_app_id", null: false
    t.string "permissible_type", null: false
    t.bigint "permissible_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["permissible_type", "permissible_id"], name: "index_platform_app_permissibles_on_permissibles"
    t.index ["platform_app_id", "permissible_id", "permissible_type"], name: "unique_permissibles_index", unique: true
    t.index ["platform_app_id"], name: "index_platform_app_permissibles_on_platform_app_id"
  end

  create_table "platform_apps", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "portal_members", force: :cascade do |t|
    t.bigint "portal_id"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["portal_id", "user_id"], name: "index_portal_members_on_portal_id_and_user_id", unique: true
    t.index ["user_id", "portal_id"], name: "index_portal_members_on_user_id_and_portal_id", unique: true
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "config", default: {"allowed_locales"=>["en"]}
    t.boolean "archived", default: false
    t.bigint "channel_web_widget_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.float "value_in_business_hours"
    t.datetime "event_start_time", precision: nil
    t.datetime "event_end_time", precision: nil
    t.index ["account_id", "name", "created_at"], name: "reporting_events__account_id__name__created_at"
    t.index ["account_id"], name: "index_reporting_events_on_account_id"
    t.index ["conversation_id"], name: "index_reporting_events_on_conversation_id"
    t.index ["created_at"], name: "index_reporting_events_on_created_at"
    t.index ["inbox_id"], name: "index_reporting_events_on_inbox_id"
    t.index ["name"], name: "index_reporting_events_on_name"
    t.index ["user_id"], name: "index_reporting_events_on_user_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["team_id", "user_id"], name: "index_team_members_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_members_on_team_id"
    t.index ["user_id"], name: "index_team_members_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "allow_auto_assign", default: true
    t.bigint "account_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["account_id"], name: "index_teams_on_account_id"
    t.index ["name", "account_id"], name: "index_teams_on_name_and_account_id", unique: true
  end

  create_table "telegram_bots", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "auth_key"
    t.integer "account_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.index ["email"], name: "index_users_on_email"
    t.index ["pubsub_token"], name: "index_users_on_pubsub_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "webhooks", force: :cascade do |t|
    t.integer "account_id"
    t.integer "inbox_id"
    t.string "url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "webhook_type", default: 0
    t.jsonb "subscriptions", default: ["conversation_status_changed", "conversation_updated", "conversation_created", "contact_created", "contact_updated", "message_created", "message_updated", "webwidget_triggered"]
    t.index ["account_id", "url"], name: "index_webhooks_on_account_id_and_url", unique: true
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "open_all_day", default: false
    t.index ["account_id"], name: "index_working_hours_on_account_id"
    t.index ["inbox_id"], name: "index_working_hours_on_inbox_id"
  end

  add_foreign_key "Chat", "Instance", column: "instanceId", name: "Chat_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Chatwoot", "Instance", column: "instanceId", name: "Chatwoot_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Contact", "Instance", column: "instanceId", name: "Contact_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Dify", "Instance", column: "instanceId", name: "Dify_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "DifySetting", "Dify", column: "difyIdFallback", name: "DifySetting_difyIdFallback_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "DifySetting", "Instance", column: "instanceId", name: "DifySetting_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "EvolutionBot", "Instance", column: "instanceId", name: "EvolutionBot_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "EvolutionBotSetting", "EvolutionBot", column: "botIdFallback", name: "EvolutionBotSetting_botIdFallback_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "EvolutionBotSetting", "Instance", column: "instanceId", name: "EvolutionBotSetting_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Flowise", "Instance", column: "instanceId", name: "Flowise_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "FlowiseSetting", "Flowise", column: "flowiseIdFallback", name: "FlowiseSetting_flowiseIdFallback_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "FlowiseSetting", "Instance", column: "instanceId", name: "FlowiseSetting_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "IntegrationSession", "Instance", column: "instanceId", name: "IntegrationSession_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Label", "Instance", column: "instanceId", name: "Label_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Media", "Instance", column: "instanceId", name: "Media_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Media", "Message", column: "messageId", name: "Media_messageId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Message", "Instance", column: "instanceId", name: "Message_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Message", "IntegrationSession", column: "sessionId", name: "Message_sessionId_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "MessageUpdate", "Instance", column: "instanceId", name: "MessageUpdate_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "MessageUpdate", "Message", column: "messageId", name: "MessageUpdate_messageId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "OpenaiBot", "Instance", column: "instanceId", name: "OpenaiBot_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "OpenaiBot", "OpenaiCreds", column: "openaiCredsId", name: "OpenaiBot_openaiCredsId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "OpenaiCreds", "Instance", column: "instanceId", name: "OpenaiCreds_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "OpenaiSetting", "Instance", column: "instanceId", name: "OpenaiSetting_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "OpenaiSetting", "OpenaiBot", column: "openaiIdFallback", name: "OpenaiSetting_openaiIdFallback_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "OpenaiSetting", "OpenaiCreds", column: "openaiCredsId", name: "OpenaiSetting_openaiCredsId_fkey", on_update: :cascade, on_delete: :restrict
  add_foreign_key "Proxy", "Instance", column: "instanceId", name: "Proxy_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Rabbitmq", "Instance", column: "instanceId", name: "Rabbitmq_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Session", "Instance", column: "sessionId", name: "Session_sessionId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Setting", "Instance", column: "instanceId", name: "Setting_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Sqs", "Instance", column: "instanceId", name: "Sqs_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Template", "Instance", column: "instanceId", name: "Template_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Typebot", "Instance", column: "instanceId", name: "Typebot_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "TypebotSetting", "Instance", column: "instanceId", name: "TypebotSetting_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "TypebotSetting", "Typebot", column: "typebotIdFallback", name: "TypebotSetting_typebotIdFallback_fkey", on_update: :cascade, on_delete: :nullify
  add_foreign_key "Webhook", "Instance", column: "instanceId", name: "Webhook_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "Websocket", "Instance", column: "instanceId", name: "Websocket_instanceId_fkey", on_update: :cascade, on_delete: :cascade
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "inboxes", "portals"
end
