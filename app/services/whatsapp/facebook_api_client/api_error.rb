# Raised for any failed Graph call. The message keeps the context and raw body that logs rely on;
# meta_message is Meta's own error text, safe to show to users.
class Whatsapp::FacebookApiClient::ApiError < StandardError
  attr_reader :meta_message

  def initialize(message, meta_message:)
    @meta_message = meta_message
    super(message)
  end
end
