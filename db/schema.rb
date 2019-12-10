# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_12_09_202758) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "attachments", id: :serial, force: :cascade do |t|
    t.string "file"
    t.integer "file_type", default: 0
    t.string "external_url"
    t.float "coordinates_lat", default: 0.0
    t.float "coordinates_long", default: 0.0
    t.integer "message_id", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "fallback_title"
    t.string "extension"
  end

  create_table "canned_responses", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "short_code"
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "channel_facebook_pages", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "page_id", null: false
    t.string "user_access_token", null: false
    t.string "page_access_token", null: false
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.index ["page_id", "account_id"], name: "index_channel_facebook_pages_on_page_id_and_account_id", unique: true
    t.index ["page_id"], name: "index_channel_facebook_pages_on_page_id"
  end

  create_table "channel_web_widgets", id: :serial, force: :cascade do |t|
    t.string "website_name"
    t.string "website_url"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "website_token"
    t.string "widget_color", default: "#1f93ff"
    t.index ["website_token"], name: "index_channel_web_widgets_on_website_token", unique: true
  end

  create_table "contact_inboxes", force: :cascade do |t|
    t.bigint "contact_id"
    t.bigint "inbox_id"
    t.string "source_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["contact_id"], name: "index_contact_inboxes_on_contact_id"
    t.index ["inbox_id", "source_id"], name: "index_contact_inboxes_on_inbox_id_and_source_id", unique: true
    t.index ["inbox_id"], name: "index_contact_inboxes_on_inbox_id"
    t.index ["source_id"], name: "index_contact_inboxes_on_source_id"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "avatar"
    t.string "pubsub_token"
    t.index ["account_id"], name: "index_contacts_on_account_id"
    t.index ["pubsub_token"], name: "index_contacts_on_pubsub_token", unique: true
  end

  create_table "conversations", id: :serial, force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "inbox_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "assignee_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "contact_id"
    t.integer "display_id", null: false
    t.datetime "user_last_seen_at"
    t.datetime "agent_last_seen_at"
    t.boolean "locked", default: false
    t.jsonb "additional_attributes"
    t.index ["account_id", "display_id"], name: "index_conversations_on_account_id_and_display_id", unique: true
    t.index ["account_id"], name: "index_conversations_on_account_id"
  end

  create_table "inbox_members", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "inbox_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inbox_id"], name: "index_inbox_members_on_inbox_id"
  end

  create_table "inboxes", id: :serial, force: :cascade do |t|
    t.integer "channel_id", null: false
    t.integer "account_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "channel_type"
    t.index ["account_id"], name: "index_inboxes_on_account_id"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.text "content"
    t.integer "account_id", null: false
    t.integer "inbox_id", null: false
    t.integer "conversation_id", null: false
    t.integer "message_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "private", default: false
    t.integer "user_id"
    t.integer "status", default: 0
    t.string "fb_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "subscriptions", id: :serial, force: :cascade do |t|
    t.string "pricing_version"
    t.integer "account_id"
    t.datetime "expiry"
    t.string "billing_plan", default: "trial"
    t.string "stripe_customer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "state", default: 0
    t.boolean "payment_source_added", default: false
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
    t.index ["tagger_type", "tagger_id"], name: "index_taggings_on_tagger_type_and_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "telegram_bots", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "auth_key"
    t.integer "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name", null: false
    t.string "nickname"
    t.string "email"
    t.json "tokens"
    t.integer "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pubsub_token"
    t.integer "role", default: 0
    t.bigint "inviter_id"
    t.index ["email"], name: "index_users_on_email"
    t.index ["inviter_id"], name: "index_users_on_inviter_id"
    t.index ["pubsub_token"], name: "index_users_on_pubsub_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contact_inboxes", "contacts"
  add_foreign_key "contact_inboxes", "inboxes"
  add_foreign_key "users", "users", column: "inviter_id", on_delete: :nullify
end
