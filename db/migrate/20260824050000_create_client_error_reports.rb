class CreateClientErrorReports < ActiveRecord::Migration[7.1]
  def change
    create_table :client_error_reports do |t|
      t.references :account, null: true, foreign_key: true
      t.string :website_token, null: false
      t.string :platform, null: false
      t.string :app_version
      t.string :environment
      t.text :message, null: false
      t.text :stack
      t.text :user_agent
      t.string :url
      t.jsonb :metadata, default: {}
      t.timestamps
    end

    add_index :client_error_reports, :website_token
    add_index :client_error_reports, :created_at
  end
end
