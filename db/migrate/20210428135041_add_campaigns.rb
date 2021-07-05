class AddCampaigns < ActiveRecord::Migration[6.0]
  def change
    create_table :campaigns do |t|
      t.integer :display_id, null: false
      t.string :title, null: false
      t.text :description
      t.text :content, null: false
      t.integer :sender_id
      t.boolean :enabled, default: true
      t.references :account, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.column :trigger_rules, :jsonb, default: {}
      t.timestamps
    end

    add_reference :conversations, :campaign, foreign_key: true
  end
end
