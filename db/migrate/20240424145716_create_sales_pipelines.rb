class CreateSalesPipelines < ActiveRecord::Migration[7.0]
  def change
    create_table :sales_pipelines do |t|
      t.integer :account_id, null: false
      t.integer :stage_type, null: false
      t.string :short_name, null: false
      t.string :name, null: false
      t.string :description, null: true
      t.integer :status, null: false
      t.boolean :disabled, null: false, default: false
      t.index [:account_id, :short_name], name: 'index_sales_pipelines_on_account_id_and_short_name', unique: true
      t.timestamps
    end
  end
end
