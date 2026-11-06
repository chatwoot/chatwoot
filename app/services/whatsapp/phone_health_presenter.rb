class Whatsapp::PhoneHealthPresenter
  FIELDS = %i[
    id
    display_phone_number
    verified_name
    name_status
    new_display_name
    new_name_status
    quality_rating
    status
    account_mode
    code_verification_status
    webhook_configuration
    throughput
    last_onboarded_time
    is_on_biz_app
    platform_type
  ].freeze

  def initialize(phone_response, expected_webhook_url:)
    @phone_response = phone_response
    @expected_webhook_url = expected_webhook_url
  end

  def perform
    FIELDS.index_with { |field| @phone_response[field.to_s] }.merge(
      messaging_limit_tier: @phone_response['whatsapp_business_manager_messaging_limit'],
      throughput_level: @phone_response.dig('throughput', 'level'),
      expected_webhook_url: @expected_webhook_url
    )
  end
end
