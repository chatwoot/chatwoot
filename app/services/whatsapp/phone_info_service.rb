class Whatsapp::PhoneInfoService
  def initialize(waba_id, phone_number_id, access_token, expected_phone_number: nil)
    @waba_id = waba_id
    @phone_number_id = phone_number_id
    @access_token = access_token
    @expected_phone_number = expected_phone_number
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
    # Paginated fetch: a WABA can hold more numbers than one Graph page, and both the id match
    # and the ambiguity check below need the complete list to be correct.
    phone_numbers = @api_client.fetch_all_phone_numbers(@waba_id)
    raise "No phone numbers found for WABA #{@waba_id}" if phone_numbers.blank?

    phone_data = find_phone_data(phone_numbers)
    raise "No matching phone number found for WABA #{@waba_id}" if phone_data.nil?

    build_phone_info(phone_data)
  end

  # A provided identifier is authoritative — no falling back to another number, which
  # could silently onboard/reauthorize the wrong one on a multi-number WABA.
  def find_phone_data(phone_numbers)
    return find_by_id(phone_numbers) if @phone_number_id.present?
    return find_by_expected_number(phone_numbers) if @expected_phone_number.present?

    # No identifier (coexistence completions send only waba_id): only a sole number is unambiguous.
    raise "Multiple phone numbers found for WABA #{@waba_id}; unable to determine the onboarded number" if phone_numbers.many?

    phone_numbers.first
  end

  def find_by_id(phone_numbers)
    phone_numbers.find { |phone| phone['id'] == @phone_number_id }
  end

  # Coexistence completions can omit phone_number_id; when reauthorizing a known channel,
  # match its existing number instead of arbitrarily taking the WABA's first number.
  def find_by_expected_number(phone_numbers)
    phone_numbers.find { |phone| matches_expected_phone_number?(phone) }
  end

  def matches_expected_phone_number?(phone)
    "+#{sanitize_phone_number(phone['display_phone_number'])}" == @expected_phone_number
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
