class WhatsappRateLimitError < StandardError
  attr_reader :retry_after, :error_code

  def initialize(message, retry_after: 300, error_code: 80_008)
    @retry_after = retry_after
    @error_code = error_code
    super(message)
  end
end
