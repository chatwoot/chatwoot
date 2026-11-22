module Enterprise::NotificationSubscriptionBuilder
  private

  def identifier
    return super unless params[:subscription_type] == 'apns_voip'

    @identifier ||= "voip:#{params[:subscription_attributes][:device_id]}"
  end
end
