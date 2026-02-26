class CreateDeals < ActiveRecord::Migration[7.0]
  def change
    create_table :deals do |t|
      t.references :account, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :pipeline_stage, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.string :name, null: false
      t.decimal :value, precision: 10, scale: 2, default: 0.0
      t.integer :status, default: 0 # 0: open, 1: won, 2: lost

      t.timestamps
    end
  end
end
