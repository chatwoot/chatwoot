class CreateCrmPipelines < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_pipelines do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :display_order, default: 0, null: false

      t.timestamps
    end
  end
end
