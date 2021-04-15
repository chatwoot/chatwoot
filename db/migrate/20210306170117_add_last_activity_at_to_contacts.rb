class AddLastActivityAtToContacts < ActiveRecord::Migration[6.0]
  def up
    # rubocop:disable Rails/SkipsModelValidations
    add_column :contacts, :last_activity_at, :datetime, index: true, default: nil
    Conversation.find_in_batches do |conversation_batch|
      conversation_batch.each do |conversation|
        contact = conversation.contact
        if contact.last_activity_at.nil? || conversation.updated_at > contact.last_activity_at
          contact.update_columns(last_activity_at: conversation.updated_at)
        end
      end
    end

    Contact.where(additional_attributes: nil).update_all(additional_attributes: {})
    Contact.where(phone_number: '').update_all(phone_number: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    remove_column :contacts, :last_activity_at, :datetime, index: true, default: nil
  end
end
