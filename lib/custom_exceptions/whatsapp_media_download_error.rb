class CustomExceptions::WhatsappMediaDownloadError < StandardError
  attr_reader :http_status

  def initialize(media_id, http_status)
    @http_status = http_status
    super("WhatsApp media lookup failed for #{media_id} (HTTP #{http_status})")
  end
end
