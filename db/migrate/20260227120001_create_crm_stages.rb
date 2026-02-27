class CreateCrmStages < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_stages do |t|
      t.references :crm_pipeline, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :stage_type, default: 0, null: false
      t.integer :display_order, default: 0, null: false

      t.timestamps
    end
  end
end
