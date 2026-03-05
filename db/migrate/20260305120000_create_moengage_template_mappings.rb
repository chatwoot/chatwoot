class CreateMoengageTemplateMappings < ActiveRecord::Migration[7.0]
  def change
    create_table :moengage_template_mappings do |t|
      t.references :account, null: false, index: true
      t.references :hook, null: false, foreign_key: { to_table: :integrations_hooks }
      t.references :inbox, null: false
      t.string :event_name, null: false
      t.string :template_name, null: false
      t.string :template_language, null: false, default: 'en'
      t.jsonb :parameter_map, null: false, default: {}
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end

    add_index :moengage_template_mappings,
              %i[account_id hook_id event_name],
              unique: true,
              name: 'idx_moengage_template_mappings_unique'
  end
end
