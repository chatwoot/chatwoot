class AddContactToMessage < ActiveRecord::Migration[6.0]
  def change
    add_reference(:messages, :contact, foreign_key: true, index: true)

    ::Message.all.each do |message|
      conversation = message.conversation
      next if conversation.contact.nil?

      message.update!(contact_id: conversation.contact.id)
    end
  end
end
