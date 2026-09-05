class Conversations::ChangeConversationInboxService
  attr_reader :conversation, :new_inbox, :new_contact_inbox, :current_user

  def initialize(conversation:, inbox_id:, current_user:)
    @conversation = conversation
    @new_inbox = conversation.account.inboxes.find(inbox_id)
    @current_user = current_user
  end

  def call
    find_or_build_contact_inbox
    update_conversation
    log_activity
    conversation
  end

  private

  def find_or_build_contact_inbox
    @new_contact_inbox = ContactInbox.find_by(
      contact_id: conversation.contact_id,
      inbox_id: new_inbox.id
    )

    return if @new_contact_inbox.present?

    @new_contact_inbox = ContactInboxBuilder.new(
      contact: conversation.contact,
      inbox: new_inbox,
      source_id: SecureRandom.uuid,
      hmac_verified: true
    ).perform
  end

  def update_conversation
    conversation.update!(inbox: new_inbox, contact_inbox: new_contact_inbox)
  end

  def log_activity
    conversation.messages.create!(
      message_type: 'activity',
      content: "Источник изменён на #{new_inbox.name} пользователем #{current_user.name}",
      account: conversation.account,
      inbox: new_inbox
    )
  end
end
