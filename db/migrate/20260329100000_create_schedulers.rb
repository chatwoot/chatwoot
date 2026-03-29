class CreateSchedulers < ActiveRecord::Migration[7.0]
  def change
    create_table :schedulers do |t|
      t.bigint :account_id, null: false
      t.bigint :inbox_id, null: false
      t.string :title, null: false
      t.string :message_type, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.jsonb :template_params, default: {}
      t.integer :display_id

      t.timestamps
    end

    add_index :schedulers, [:account_id, :message_type], unique: true
    add_index :schedulers, :account_id
    add_index :schedulers, :inbox_id
  end
end
