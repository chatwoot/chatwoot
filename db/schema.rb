# Database schema is being defined (using Rails version 7.1)
ActiveRecord::Schema[7.1].define(version: 2025_08_08_123008) do

  # Required PostgreSQL extensions
  enable_extension "pg_trgm"     # Text similarity via trigram search
  enable_extension "pgcrypto"    # Encryption and UUID generation
  enable_extension "plpgsql"     # Procedural language support for PostgreSQL
  enable_extension "vector"      # Vector-based search (e.g., for AI integration)

  # Table: accounts
  create_table "accounts", force: :cascade do |t|
    t.string   "name", null: false                 # Account name (required)
    t.datetime "created_at", null: false           # Record creation timestamp
    t.datetime "updated_at", null: false           # Record update timestamp
    t.integer  "locale", default: 0                # Locale setting
    t.string   "domain", limit: 100                # Domain (max 100 characters)
    t.string   "support_email", limit: 100         # Support email address
    t.jsonb    "settings", default: {}             # Account settings in JSON
  end

  # Table: users
  create_table "users", force: :cascade do |t|
    t.string   "email"                             # Email address
    t.string   "name", null: false                 # User name (required)
    t.string   "encrypted_password", default: "", null: false  # Encrypted password
    t.datetime "created_at", null: false           # Record creation timestamp
    t.datetime "updated_at", null: false           # Record update timestamp
  end

  # Table: conversations
  create_table "conversations", force: :cascade do |t|
    t.integer  "account_id", null: false           # Associated account ID
    t.integer  "inbox_id", null: false             # Associated inbox ID
    t.integer  "status", default: 0, null: false   # Conversation status (default: 0)
    t.datetime "created_at", null: false           # Record creation timestamp
    t.datetime "updated_at", null: false           # Record update timestamp
  end

end
