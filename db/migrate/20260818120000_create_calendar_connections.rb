class CreateCalendarConnections < ActiveRecord::Migration[7.1]
  def up
    create_table :calendar_connections do |t|
      t.references :account, null: false, foreign_key: true
      t.string :provider, null: false, default: 'google'
      t.string :email, null: false
      t.text :refresh_token, null: false
      t.text :access_token
      t.datetime :access_token_expires_at
      t.jsonb :scopes, null: false, default: []
      t.boolean :is_active, null: false, default: true
      t.references :connected_by, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :calendar_connections, [:account_id, :provider, :email], unique: true,
                                                                       name: 'index_calendar_connections_on_account_provider_email'
    add_index :calendar_connections, [:account_id, :is_active]

    Account.find_each { |account| account.enable_features!('calendar_integration') }
  end

  def down
    Account.find_each { |account| account.disable_features!('calendar_integration') }
    drop_table :calendar_connections
  end
end
