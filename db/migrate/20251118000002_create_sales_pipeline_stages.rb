class CreateSalesPipelineStages < ActiveRecord::Migration[7.1]
  def change
    create_table :sales_pipeline_stages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :sales_pipeline, null: false, foreign_key: true
      t.references :label, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, null: false
      t.integer :position, null: false
      t.boolean :is_default, default: false, null: false
      t.boolean :is_closed_won, default: false, null: false
      t.boolean :is_closed_lost, default: false, null: false
      t.timestamps
    end

    add_index :sales_pipeline_stages, [:account_id, :sales_pipeline_id, :position], unique: true, name: 'index_sales_pipeline_stages_on_order'
    add_index :sales_pipeline_stages, [:account_id, :label_id], unique: true
    add_index :sales_pipeline_stages, [:account_id, :is_default], unique: true, where: 'is_default = true'
  end
end