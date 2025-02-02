# db/migrate/[TIMESTAMP]_add_message_id_to_campaign_contacts.rb
class AddMessageIdToCampaignContacts < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns_contacts, :message_id, :string
    add_index :campaigns_contacts, :message_id
  end
end
