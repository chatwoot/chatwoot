ActiveRecord::Schema[7.1].define(version: 2025_08_08_123008) do
  # Gerekli uzantılar
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "vector"

  # Örnek tablo: accounts
  create_table "accounts", force: :cascade do |t|
    t.string   "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "locale", default: 0
    t.string   "domain", limit: 100
    t.string   "support_email", limit: 100
    t.jsonb    "settings", default: {}
  end

  # Örnek tablo: users
  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "name", null: false
    t.string   "encrypted_password", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  # Örnek tablo: conversations
  create_table "conversations", force: :cascade do |t|
    t.integer  "account_id", null: false
    t.integer  "inbox_id", null: false
    t.integer  "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
