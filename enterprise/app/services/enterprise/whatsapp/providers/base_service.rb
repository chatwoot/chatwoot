module Enterprise::Whatsapp::Providers::BaseService
  attr_reader :last_error

  def process_response(response, message)
    @last_error = nil
    super
  end

  def handle_error(response, message)
    @last_error = parsed_error(response)
    super
  end

  private

  def parsed_error(response)
    parsed_response = response.parsed_response
    error = parsed_response.is_a?(Hash) ? parsed_response['error'] || {} : {}
    {
      code: error['code'],
      title: error['error_user_title'].presence || error['title'],
      message: error['error_user_msg'].presence || error.dig('error_data', 'details').presence || error['message'].presence
    }.compact_blank.presence
  end
end
