class CreateVouchers < ActiveRecord::Migration[7.0]
  def change
    create_table :vouchers do |t|
      t.string  :name, null: false
      t.string  :code, null: false, index: { unique: true }
      t.string  :discount_type, null: false # 'idr' or 'percentage'
      t.integer :discount_value, null: false
      t.date    :start_date, null: false
      t.date    :end_date, null: false
      t.boolean :is_recurring, default: false
      t.integer :usage_limit # optional

      t.timestamps
    end
  end
end
