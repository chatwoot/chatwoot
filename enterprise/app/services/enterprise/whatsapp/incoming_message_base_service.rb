module Enterprise::Whatsapp::IncomingMessageBaseService
  def process_messages
    super
    attribute_conversation_to_whatsapp_campaign
  end

  private

  def attribute_conversation_to_whatsapp_campaign
    return if @conversation.blank?
    return if messages_data.blank?

    Whatsapp::CampaignConversationAttributor.new(
      conversation: @conversation,
      inbox: inbox,
      message_payload: messages_data.first,
      outgoing_echo: outgoing_echo
    ).perform
  end

  def process_statuses
    status = @processed_params[:statuses].first
    recipient = CampaignRecipient.find_by(account_id: inbox.account_id, inbox_id: inbox.id, source_id: status[:id])
    recipient&.update_from_whatsapp_status!(status)

    super

    return if recipient || @message
    return unless inbox.account.feature_enabled?(:whatsapp_campaign)
    return unless %w[delivered read failed].include?(status[:status].to_s)

    Campaigns::UpdateRecipientStatusJob.set(wait: 2.seconds).perform_later(inbox.id, status.to_h)
  end
end
