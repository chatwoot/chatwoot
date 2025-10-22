class NumberFormatConfig < ActiveRecord::Migration[7.0]
  def change
    create_table :number_format_configs do |t|
      t.string :format, default: 'INV/'
      t.integer :current_number, default: 1
      t.string :reset_every, default: 'never'
      t.references :account, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
