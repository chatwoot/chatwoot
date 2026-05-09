class CreateIntegrationsIssueLinks < ActiveRecord::Migration[7.0]
  def change
    create_table :integrations_issue_links do |t|
      t.references :account, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :app_id, null: false
      t.string :external_id, null: false
      t.text :external_url, null: false
      t.string :external_title
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :integrations_issue_links, [:account_id, :app_id, :external_id],
              unique: true,
              name: 'index_issue_links_on_account_app_external_id'
    add_index :integrations_issue_links, [:conversation_id, :app_id]
  end
end
