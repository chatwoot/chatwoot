module Enterprise::Whatsapp::IncomingMessageBaseService
  private

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
