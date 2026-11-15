module Enterprise::NotificationSubscriptionBuilder
  private

  # A device keeps its FCM row; the VoIP token is a second row keyed on the same device
  def identifier
    return super unless params[:subscription_type] == 'apns_voip'

    @identifier ||= "voip:#{params[:subscription_attributes][:device_id]}"
  end
end
