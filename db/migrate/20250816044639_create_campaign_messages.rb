class CreateCampaignMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :campaign_messages do |t|
      t.references :campaign, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :message_id
      t.string :status, default: 'pending', null: false, index: true
      t.string :error_code
      t.text :error_description
      t.datetime :sent_at
      t.datetime :delivered_at
      t.datetime :read_at

      t.timestamps
    end

    add_index :campaign_messages, [:campaign_id, :status]
    add_index :campaign_messages, :contact_id unless index_exists?(:campaign_messages, :contact_id)
    add_index :campaign_messages, :message_id, unique: true
  end
end
