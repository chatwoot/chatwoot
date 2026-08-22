class Whatsapp::CampaignConversationAttributor
  pattr_initialize [:conversation!, :inbox!, :message_payload!, :outgoing_echo]

  def perform
    return if outgoing_echo
    return unless inbox.account.feature_enabled?(:whatsapp_campaign)
    return if conversation.campaign_id.present?

    context_id = message_payload[:context]&.dig(:id) || message_payload[:context]&.[]('id')
    return if context_id.blank?

    # ponytail: only Meta reply context (buttons / quoted reply); no heuristic for free-text replies
    recipient = CampaignRecipient.find_by(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      source_id: context_id
    )
    return unless recipient

    conversation.update!(campaign_id: recipient.campaign_id)
  end
end
