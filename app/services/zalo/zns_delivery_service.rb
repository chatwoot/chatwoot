class Zalo::ZnsDeliveryService
  pattr_initialize [:params!]

  def perform
    return unless params[:event_name] == 'user_received_message'

    campaign = Campaign.find(params[:message][:tracking_id])
    return unless campaign

    campaign.update(received_count: received_count + 1)
  end
end
