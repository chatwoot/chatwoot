class AddContactInboxToConversation < ActiveRecord::Migration[6.0]
  def change
    add_reference(:conversations, :contact_inboxes)

    ::Conversation.all.each do |conversation|
      contact_inbox = ::ContactInbox.find_by(
        contact_id: conversation.contact_id,
        inbox_id: conversation.inbox_id
      )

      conversation.update!(contact_inboxes_id: contact_inbox.id)
    end
  end
end
