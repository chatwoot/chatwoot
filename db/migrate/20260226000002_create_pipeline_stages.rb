class CreatePipelineStages < ActiveRecord::Migration[7.0]
  def change
    create_table :pipeline_stages do |t|
      t.references :pipeline, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
