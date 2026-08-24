module Enterprise::Channel::Whatsapp
  attr_reader :last_provider_error

  def send_template(...)
    provider = provider_service
    response = provider.send_template(...)
    @last_provider_error = provider.last_error
    response
  end
end
