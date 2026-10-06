class CreateDoorkeeperTables < ActiveRecord::Migration[7.2]
  def change
    create_applications
    create_access_grants
    create_access_tokens
  end

  private

  def create_applications
    create_table :oauth_applications do |t|
      t.string  :name,    null: false
      t.string  :uid,     null: false
      # Nullable because dynamically registered clients are public and hold no secret.
      t.string  :secret
      t.text    :redirect_uri, null: false
      t.string  :scopes,       null: false, default: ''
      t.boolean :confidential, null: false, default: true
      t.timestamps             null: false
    end

    add_index :oauth_applications, :uid, unique: true
  end

  def create_access_grants
    create_table :oauth_access_grants do |t|
      t.references :resource_owner,  null: false
      t.references :application,     null: false
      t.bigint   :account_id,        null: false
      t.string   :token,             null: false
      t.integer  :expires_in,        null: false
      t.text     :redirect_uri,      null: false
      t.string   :scopes,            null: false, default: ''
      t.string   :code_challenge
      t.string   :code_challenge_method
      t.datetime :created_at,        null: false
      t.datetime :revoked_at
    end

    add_index :oauth_access_grants, :token, unique: true
  end

  def create_access_tokens
    create_table :oauth_access_tokens do |t|
      t.references :resource_owner, index: true
      t.references :application,    null: false
      t.bigint   :account_id,       null: false
      t.string   :token,            null: false
      t.string   :refresh_token
      t.integer  :expires_in
      t.string   :scopes
      t.datetime :created_at, null: false
      t.datetime :revoked_at
      # No previous_refresh_token column: Doorkeeper then revokes the old token as soon as it is refreshed.
    end

    add_index :oauth_access_tokens, :token, unique: true
    add_index :oauth_access_tokens, :refresh_token, unique: true
  end
end
