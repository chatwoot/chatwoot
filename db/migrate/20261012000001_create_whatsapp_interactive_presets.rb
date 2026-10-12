class CreateWhatsappInteractivePresets < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_interactive_presets do |t|
      t.references :account, null: false, index: true
      t.references :created_by, null: true, index: true
      t.string :name, null: false
      t.string :interactive_type, null: false
      t.integer :schema_version, null: false
      t.jsonb :definition, null: false, default: {}
      t.datetime :archived_at
      t.timestamps
    end

    add_index :whatsapp_interactive_presets, [:account_id, :name]
  end
end
