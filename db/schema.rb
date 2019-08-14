# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171014113353) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "attachments", force: :cascade do |t|
    t.string   "file"
    t.integer  "file_type",        default: 0
    t.string   "external_url"
    t.float    "coordinates_lat",  default: 0.0
    t.float    "coordinates_long", default: 0.0
    t.integer  "message_id",                     null: false
    t.integer  "account_id",                     null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.string   "fallback_title"
    t.string   "extension"
  end

  create_table "canned_responses", force: :cascade do |t|
    t.integer  "account_id", null: false
    t.string   "short_code"
    t.text     "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "channel_widgets", force: :cascade do |t|
    t.string   "website_name"
    t.string   "website_url"
    t.integer  "account_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "contacts", force: :cascade do |t|
    t.string    "name"
    t.string    "email"
    t.string    "phone_number"
    t.integer   "account_id",   null: false
    t.datetime  "created_at",   null: false
    t.datetime  "updated_at",   null: false
    t.integer   "inbox_id",     null: false
    t.bigserial "source_id",    null: false
    t.string    "avatar"
    t.string    "chat_channel"
    t.index ["account_id"], name: "index_contacts_on_account_id", using: :btree
  end

  create_table "conversations", force: :cascade do |t|
    t.integer  "account_id",                         null: false
    t.integer  "inbox_id",                           null: false
    t.integer  "status",             default: 0,     null: false
    t.integer  "assignee_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.bigint   "sender_id"
    t.integer  "display_id",                         null: false
    t.datetime "user_last_seen_at"
    t.datetime "agent_last_seen_at"
    t.boolean  "locked",             default: false
    t.index ["account_id", "display_id"], name: "index_conversations_on_account_id_and_display_id", unique: true, using: :btree
    t.index ["account_id"], name: "index_conversations_on_account_id", using: :btree
  end

  create_table "facebook_pages", force: :cascade do |t|
    t.string   "name",              null: false
    t.string   "page_id",           null: false
    t.string   "user_access_token", null: false
    t.string   "page_access_token", null: false
    t.integer  "account_id",        null: false
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "avatar"
    t.index ["page_id"], name: "index_facebook_pages_on_page_id", using: :btree
  end

  create_table "inbox_members", force: :cascade do |t|
    t.integer  "user_id",    null: false
    t.integer  "inbox_id",   null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["inbox_id"], name: "index_inbox_members_on_inbox_id", using: :btree
  end

  create_table "inboxes", force: :cascade do |t|
    t.integer  "channel_id",   null: false
    t.integer  "account_id",   null: false
    t.string   "name",         null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "channel_type"
    t.index ["account_id"], name: "index_inboxes_on_account_id", using: :btree
  end

  create_table "messages", force: :cascade do |t|
    t.text     "content"
    t.integer  "account_id",                      null: false
    t.integer  "inbox_id",                        null: false
    t.integer  "conversation_id",                 null: false
    t.integer  "message_type",                    null: false
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "private",         default: false
    t.integer  "user_id"
    t.integer  "status",          default: 0
    t.string   "fb_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id", using: :btree
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "pricing_version"
    t.integer  "account_id"
    t.datetime "expiry"
    t.string   "billing_plan",         default: "trial"
    t.string   "stripe_customer_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "state",                default: 0
    t.boolean  "payment_source_added", default: false
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.string   "taggable_type"
    t.integer  "taggable_id"
    t.string   "tagger_type"
    t.integer  "tagger_id"
    t.string   "context",       limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context", using: :btree
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
    t.index ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
  end

  create_table "telegram_bots", force: :cascade do |t|
    t.string   "name"
    t.string   "auth_key"
    t.integer  "account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider",               default: "email", null: false
    t.string   "uid",                    default: "",      null: false
    t.string   "encrypted_password",     default: "",      null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,       null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "name",                                     null: false
    t.string   "nickname"
    t.string   "image"
    t.string   "email"
    t.json     "tokens"
    t.integer  "account_id",                               null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "channel"
    t.integer  "role",                   default: 0
    t.index ["email"], name: "index_users_on_email", using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true, using: :btree
  end

end
