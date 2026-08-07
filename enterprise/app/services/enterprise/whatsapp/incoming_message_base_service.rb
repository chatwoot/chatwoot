module Enterprise::Whatsapp::IncomingMessageBaseService
  private

  def process_statuses
    status = @processed_params[:statuses].first
    CampaignRecipient.find_by(source_id: status[:id])&.update_from_whatsapp_status!(status)

    super
  end
end
