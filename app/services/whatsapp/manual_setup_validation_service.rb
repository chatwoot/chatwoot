class Whatsapp::ManualSetupValidationService
  LOG_PREFIX = '[WHATSAPP MANUAL SETUP]'.freeze
  MESSAGING_PERMISSION = 'whatsapp_business_messaging'.freeze

  def initialize(waba_id:, phone_number_id:, access_token:)
    @waba_id = waba_id
    @phone_number_id = phone_number_id
    @access_token = access_token
    @api_client = Whatsapp::FacebookApiClient.new(access_token)
  end

  def perform
    validate_parameters!
    Rails.logger.info "#{LOG_PREFIX} Validation started waba_id=#{@waba_id} phone_number_id=#{@phone_number_id}"

    phone_data = find_phone_data!.merge(
      @api_client.fetch_phone_number(@phone_number_id, fields: 'status,code_verification_status')
    )
    Rails.logger.info "#{LOG_PREFIX} Matched phone_number_id=#{@phone_number_id} fields=#{phone_data.keys.sort.join(',')} " \
                      "status=#{phone_data['status'].inspect} " \
                      "code_verification_status=#{phone_data['code_verification_status'].inspect} " \
                      "name_status=#{phone_data['name_status'].inspect}"
    verify_phone_number_ready!(phone_data)
    verify_uniqueness!(phone_data)
    verify_template_access!
    verify_messaging_access!

    build_preview(phone_data)
  end

  private

  def validate_parameters!
    raise ArgumentError, 'WABA ID is required' if @waba_id.blank?
    raise ArgumentError, 'Phone Number ID is required' if @phone_number_id.blank?
    raise ArgumentError, 'Access token is required' if @access_token.blank?
  end

  def find_phone_data!
    phone_numbers = @api_client.fetch_all_phone_numbers(@waba_id)
    returned_phone_number_ids = phone_numbers.filter_map { |phone| phone['id'] }.join(',')
    Rails.logger.info "#{LOG_PREFIX} Meta returned #{phone_numbers.size} phone number(s) for waba_id=#{@waba_id} " \
                      "phone_number_ids=#{returned_phone_number_ids}"

    phone_data = phone_numbers.find { |phone| phone['id'].to_s == @phone_number_id.to_s }
    raise ArgumentError, 'This Phone Number ID does not belong to the WABA ID you entered.' if phone_data.blank?

    phone_data
  end

  def verify_phone_number_ready!(phone_data)
    return if phone_data['status'] == 'CONNECTED' || phone_data['code_verification_status'] == 'VERIFIED'

    raise ArgumentError, 'Complete phone number verification in Meta before continuing.'
  end

  def verify_uniqueness!(phone_data)
    phone_number = normalized_phone_number(phone_data['display_phone_number'])
    raise ArgumentError, 'This WhatsApp number is already connected to another inbox.' if Channel::Whatsapp.exists?(phone_number: phone_number)

    duplicate_phone_id = Channel::Whatsapp.exists?(["provider_config->>'phone_number_id' = ?", @phone_number_id.to_s])
    raise ArgumentError, 'This Phone Number ID is already used by another WhatsApp inbox.' if duplicate_phone_id
  end

  def verify_template_access!
    @api_client.fetch_message_templates(@waba_id)
  rescue StandardError
    raise ArgumentError,
          'The token can access the number but cannot access message templates. Generate a token with whatsapp_business_management permission.'
  end

  def verify_messaging_access!
    permissions = @api_client.fetch_permissions.fetch('data', [])
    permission_granted = Array(permissions).any? do |permission|
      permission.is_a?(Hash) && permission['permission'] == MESSAGING_PERMISSION && permission['status'] == 'granted'
    end

    return if permission_granted

    raise ArgumentError
  rescue StandardError
    raise ArgumentError,
          'The token cannot access WhatsApp messaging. Generate a token with whatsapp_business_messaging permission.'
  end

  def build_preview(phone_data)
    phone_number = normalized_phone_number(phone_data['display_phone_number'])
    verified_name = phone_data['verified_name'].presence

    {
      verified_name: verified_name,
      display_phone_number: phone_number,
      phone_number_id: phone_data['id'].to_s,
      waba_id: @waba_id.to_s,
      template_access: true,
      suggested_inbox_name: "#{verified_name || phone_number} WhatsApp"
    }
  end

  def normalized_phone_number(phone_number)
    digits = phone_number.to_s.gsub(/[^\d]/, '')
    "+#{digits}"
  end
end
