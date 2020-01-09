class AddContactInboxToConversation < ActiveRecord::Migration[6.0]
  def change
    add_reference(:conversations, :contact_inbox, foreign_key: true, index: true)

    ::Conversation.all.each do |conversation|
      contact_inbox = ::ContactInbox.find_by(
        contact_id: conversation.contact_id,
        inbox_id: conversation.inbox_id
      )

      conversation.update!(contact_inbox_id: contact_inbox.id) if contact_inbox
    end
  end
end
