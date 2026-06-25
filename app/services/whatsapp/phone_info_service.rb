class Whatsapp::PhoneInfoService
  def initialize(waba_id, phone_number_id, access_token)
    @waba_id = waba_id
    @phone_number_id = phone_number_id
    @access_token = access_token
    @api_client = Whatsapp::FacebookApiClient.new(access_token)
  end

  def perform
    validate_parameters!
    fetch_and_process_phone_info
  end

  private

  def validate_parameters!
    raise ArgumentError, 'WABA ID is required' if @waba_id.blank?
    raise ArgumentError, 'Access token is required' if @access_token.blank?
  end

  def fetch_and_process_phone_info
    response = @api_client.fetch_phone_numbers(@waba_id)
    phone_numbers = response['data']

    phone_data = find_phone_data(phone_numbers)
    raise "No phone numbers found for WABA #{@waba_id}" if phone_data.nil?

    build_phone_info(phone_data)
  end

  def find_phone_data(phone_numbers)
    return nil if phone_numbers.blank?

    if @phone_number_id.present?
      phone_numbers.find { |phone| phone['id'] == @phone_number_id } || phone_numbers.first
    else
      phone_numbers.first
    end
  end

  def build_phone_info(phone_data)
    display_phone_number = sanitize_phone_number(phone_data['display_phone_number'])

    {
      phone_number_id: phone_data['id'],
      phone_number: "+#{display_phone_number}",
      verified: phone_data['code_verification_status'] == 'VERIFIED',
      business_name: phone_data['verified_name'] || phone_data['display_phone_number']
    }
  end

  def sanitize_phone_number(phone_number)
    return phone_number if phone_number.blank?

    phone_number.gsub(/[\s\-\(\)\.\+]/, '').strip
  end
end
