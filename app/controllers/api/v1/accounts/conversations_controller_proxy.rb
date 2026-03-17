module Api::V1::Accounts::ConversationsControllerProxy
  def change_inbox
    widget_conversation = Current.account.conversations.find_by!(display_id: params[:id])
    authorize widget_conversation, :update?

    target_inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize target_inbox, :show?

    operator_conversation = nil

    ActiveRecord::Base.transaction do
      contact_inbox = find_or_create_contact_inbox(widget_conversation.contact, target_inbox)

      operator_conversation = Conversation.create!(account: widget_conversation.account, inbox: target_inbox,
                                                   contact: widget_conversation.contact, contact_inbox: contact_inbox,
                                                   additional_attributes: (widget_conversation.additional_attributes || {}).merge(
                                                     'linked_conversation_id' => widget_conversation.id
                                                   ),
                                                   custom_attributes: widget_conversation.custom_attributes)

      widget_conversation.update!(
        additional_attributes: (widget_conversation.additional_attributes || {}).merge('linked_conversation_id' => operator_conversation.id)
      )
    end

    render json: { success: true, inbox_id: target_inbox.id,
                   website_token: target_inbox.channel.respond_to?(:website_token) ? target_inbox.channel.website_token : nil }
  rescue StandardError => e
    Rails.logger.error("ConversationsControllerProxy#change_inbox failed: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render json: { error: 'Could not change inbox' }, status: :unprocessable_entity
  end

  private

  def find_or_create_contact_inbox(contact, inbox)
    existing = ContactInbox.find_by(contact: contact, inbox: inbox)
    return existing if existing

    ci = ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: SecureRandom.uuid).perform

    unless ci
      ci = ContactInbox.new(contact: contact, inbox: inbox, source_id: SecureRandom.uuid)
      ci.save(validate: false)
    end

    ci
  end
end
