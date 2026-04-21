class CreateSynapseosPipelineStages < ActiveRecord::Migration[7.1]
  def change
    create_table :synapseos_pipeline_stages do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.string :name, null: false
      t.string :color, null: false, default: '#2196F3'
      t.integer :position, null: false, default: 0

      # 'inbound' | 'working' | 'won' | 'lost' | 'custom'
      t.string :stage_type, null: false, default: 'custom'

      t.timestamps
    end

    add_index :synapseos_pipeline_stages, [:account_id, :position]
    add_index :synapseos_pipeline_stages, [:account_id, :name], unique: true
  end
end
