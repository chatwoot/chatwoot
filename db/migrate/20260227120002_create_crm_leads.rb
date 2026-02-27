class CreateCrmLeads < ActiveRecord::Migration[7.0]
  def change
    create_table :crm_leads do |t|
      t.references :account, null: false, foreign_key: true
      t.references :crm_stage, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :conversation, foreign_key: true
      t.references :user, foreign_key: true
      t.string :title, null: false
      t.decimal :value
      t.datetime :expected_closing_at
      t.integer :priority, default: 0, null: false

      t.timestamps
    end
  end
end
