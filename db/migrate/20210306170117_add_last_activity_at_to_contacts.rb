class AddLastActivityAtToContacts < ActiveRecord::Migration[6.0]
  def up
    add_column :contacts, :last_activity_at, :datetime, index: true, default: nil
    # Contact.find_in_batches do |contact_batch|
    #   Rails.logger.debug "Migrated till #{contact_batch.first.id}\n"
    #   contact_batch.each do |contact|
    #     last_activity_at = contact.messages.last&.created_at
    #     contact.update_columns(last_activity_at: last_activity_at)
    #   end
    # end
  end

  def down
    remove_column :contacts, :last_activity_at, :datetime, index: true, default: nil
  end
end
