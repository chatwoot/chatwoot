class TransferCsatSettingsToInbox < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :csat_trigger, :string
    remove_column :accounts, :csat_trigger
  end
end
