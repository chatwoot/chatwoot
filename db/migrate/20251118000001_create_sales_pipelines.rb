class CreateSalesPipelines < ActiveRecord::Migration[7.1]
  def change
    create_table :sales_pipelines do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false, default: 'Vendas'
      t.timestamps
    end

    add_index :sales_pipelines, [:account_id, :name], unique: true
  end
end