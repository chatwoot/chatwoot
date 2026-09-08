class Whatsapp::BusinessProfileService
  BASE_URI = 'https://graph.facebook.com'.freeze
  FIELDS = %w[about address description email profile_picture_url websites vertical].freeze

  def initialize(channel, api_version:)
    @channel = channel
    @api_version = api_version
  end

  def fetch
    response = HTTParty.get(
      "#{BASE_URI}/#{@api_version}/#{@channel.provider_config['phone_number_id']}/whatsapp_business_profile",
      query: {
        fields: FIELDS.join(','),
        access_token: @channel.provider_config['api_key']
      }
    )

    unless response.success?
      log_error(response)
      return nil
    end

    parsed_response = response.parsed_response
    profile = parsed_response.is_a?(Hash) ? Array(parsed_response['data']).first : nil
    profile if profile.is_a?(Hash)
  rescue StandardError => e
    phone_number_id = @channel.provider_config['phone_number_id']
    Rails.logger.warn("[WHATSAPP HEALTH] Business profile unavailable: phone_number_id=#{phone_number_id} error_class=#{e.class.name}")
    nil
  end

  private

  def log_error(response)
    parsed_response = response.parsed_response
    error_data = parsed_response['error'] if parsed_response.is_a?(Hash)
    error_data = {} unless error_data.is_a?(Hash)

    Rails.logger.warn(
      "[WHATSAPP HEALTH] Business profile unavailable: http_status=#{response.code} " \
      "code=#{error_data['code']} subcode=#{error_data['error_subcode']} message=#{error_data['message']}"
    )
  end
end
