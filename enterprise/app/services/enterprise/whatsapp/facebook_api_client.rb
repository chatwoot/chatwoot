module Enterprise::Whatsapp::FacebookApiClient
  def webhook_subscribed_fields
    super + %w[calls]
  end
end
