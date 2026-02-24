class CreatePipelineStages < ActiveRecord::Migration[7.0]
  def change
    create_table :pipeline_stages do |t|
      t.references :label, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :pipeline_stages, %i[label_id position]
    add_index :pipeline_stages, %i[label_id title], unique: true
  end
end
