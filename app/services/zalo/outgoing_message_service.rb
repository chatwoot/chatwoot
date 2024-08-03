class Zalo::OutgoingMessageService
  include ::ZaloAttachmentHelper

  pattr_initialize [:inbox!, :params!]

  def perform
    set_contact
    return unless @contact

    set_conversation
    return unless @conversation

    @message = @conversation.messages.build(message_params)

    @message.content_attributes[:in_reply_to_external_id] = params[:message][:quote_msg_id] if params[:message][:quote_msg_id]

    attach_media
    @message.save!
  end

  private

  def account
    @account ||= @inbox.account
  end

  def channel
    @channel ||= @inbox.channel
  end

  def set_contact
    contact_inbox = ContactInbox.find_by(source_id: params[:recipient][:id])
    return unless contact_inbox

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def message_params
    {
      content: params[:message][:text],
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :outgoing,
      source_id: params[:message][:msg_id]
    }
  end

  def set_conversation
    @conversation = if @inbox.lock_to_single_conversation
                      @contact_inbox.conversations.last
                    else
                      @contact_inbox.conversations.where
                                    .not(status: :resolved)
                                    .order(updated_at: :asc).last
                    end
  end
end
