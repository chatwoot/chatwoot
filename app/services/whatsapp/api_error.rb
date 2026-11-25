# Meta answers a refusal with a body carrying a numeric code, and exactly one of those codes is a
# statement about the credentials. Everything else is a refusal of this request: `(#200) Permissions
# error` for a WABA in someone else's portfolio, a rate limit, a plain 500. The difference is not
# cosmetic, because it decides whether the operator gets an alarm they have to act on by hand.
#
# So the error carries what it takes to tell the two apart, and the question is asked in exactly one
# place: two classes each deciding what `190` means is how the two answers drift apart.
class Whatsapp::ApiError < StandardError
  AUTHORIZATION_ERROR_CODE = 190

  attr_reader :http_status, :code, :subcode

  def initialize(message:, http_status:, code: nil, subcode: nil)
    super(message)
    @http_status = http_status
    @code = code
    @subcode = subcode
  end

  # `message:` is for a caller that prefixes the step that failed ("Phone registration failed: ...")
  # and needs Meta's body in the line; without it the error speaks Meta's own message.
  #
  # A body that is not a Hash is Meta not answering in the vocabulary it documents (an HTML page from
  # something in front of it), and it leaves the code nil, which is the honest reading: no answer
  # about the credentials.
  def self.from_response(response, message: nil)
    error = response.parsed_response.is_a?(Hash) ? response.parsed_response['error'].to_h : {}

    new(
      message: message || error['message'].presence || 'WhatsApp API request failed',
      http_status: response.code,
      code: error['code'],
      subcode: error['error_subcode']
    )
  end

  def authorization_error?
    code.to_i == AUTHORIZATION_ERROR_CODE
  end
end
