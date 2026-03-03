class CreateWhatsappFlows < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_flows do |t|
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.string :name, null: false, limit: 255
      t.integer :status, null: false, default: 0
      t.string :flow_id, limit: 255
      t.jsonb :categories, default: []
      t.jsonb :flow_json, null: false, default: {}
      t.jsonb :validation_errors, default: []
      t.string :preview_url
      t.jsonb :endpoint_uri

      t.timestamps
    end

    add_index :whatsapp_flows, :flow_id, unique: true, where: 'flow_id IS NOT NULL'
    add_index :whatsapp_flows, :status
    add_index :whatsapp_flows, [:account_id, :inbox_id]
  end
end
