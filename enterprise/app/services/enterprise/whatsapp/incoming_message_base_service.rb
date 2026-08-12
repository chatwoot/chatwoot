module Enterprise::Whatsapp::IncomingMessageBaseService
  private

  def process_statuses
    super

    @processed_params[:statuses].each { |status| process_campaign_recipient_status(status) }
  end

  def process_campaign_recipient_status(status)
    recipient = CampaignRecipient.find_by(account_id: inbox.account_id, inbox_id: inbox.id, source_id: status[:id])
    return recipient.update_from_whatsapp_status!(status) if recipient

    return if Message.exists?(inbox_id: inbox.id, source_id: status[:id])
    return unless inbox.account.feature_enabled?(:whatsapp_campaign)
    return unless %w[delivered read failed].include?(status[:status].to_s)

    Campaigns::UpdateRecipientStatusJob.set(wait: 2.seconds).perform_later(inbox.id, status.to_h)
  end
end
