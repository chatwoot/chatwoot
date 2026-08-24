class CreateWhiskerAiProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :whisker_ai_providers do |t|
      t.bigint :account_id, null: false
      t.string :name, null: false
      t.string :base_url, null: false
      t.string :api_key
      t.jsonb :models, null: false, default: []
      t.boolean :is_primary, null: false, default: false
      t.integer :fallback_order, default: 0
      t.decimal :monthly_cap, precision: 10, scale: 2
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :whisker_ai_providers, :account_id
    add_index :whisker_ai_providers, [:account_id, :is_primary], unique: true, where: 'is_primary = true'
  end
end
