# Service to handle phone number normalization for WhatsApp messages
# Currently supports Brazil and Argentina phone number format variations
# Supports both WhatsApp Cloud API and Twilio WhatsApp providers
class Whatsapp::PhoneNumberNormalizationService
  def initialize(inbox)
    @inbox = inbox
  end

  # @param raw_number [String] The phone number in provider-specific format
  #   - Cloud: "5541988887777" (clean number)
  #   - Twilio: "whatsapp:+5541988887777" (prefixed format)
  # @param provider [Symbol] :cloud or :twilio
  # @return [String] Existing source_id if found, otherwise original incoming raw_number
  def normalize_and_find_contact_by_provider(raw_number, provider)
    clean_number = extract_clean_number(raw_number, provider)

    normalizer = find_normalizer_for_country(clean_number)
    return raw_number unless normalizer

    possible_numbers = possible_numbers_for(clean_number, normalizer)

    possible_numbers.each do |possible_number|
      provider_format = format_for_provider(possible_number, provider)
      existing_contact_inbox = find_existing_contact_inbox(provider_format)

      return existing_contact_inbox.source_id if existing_contact_inbox
    end

    raw_number
  end

  private

  attr_reader :inbox

  def possible_numbers_for(clean_number, normalizer)
    numbers = [clean_number, normalizer.normalize(clean_number)]

    if normalizer.is_a?(Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer)
      numbers.concat(brazil_possible_numbers(clean_number))
    elsif normalizer.is_a?(Whatsapp::PhoneNormalizers::ArgentinaPhoneNormalizer)
      numbers.concat(argentina_possible_numbers(clean_number))
    end

    numbers.compact.uniq
  end

  def brazil_possible_numbers(clean_number)
    return [] unless clean_number.start_with?('55')

    country_code = clean_number[0, 2]
    area_code = clean_number[2, 2]
    subscriber_number = clean_number[4..]

    return [] if area_code.blank? || subscriber_number.blank?

    possible_numbers = []

    if clean_number.length == 12
      possible_numbers << "#{country_code}#{area_code}9#{subscriber_number}"
    elsif clean_number.length == 13 && clean_number[4] == '9'
      possible_numbers << "#{country_code}#{area_code}#{clean_number[5..]}"
    end

    possible_numbers
  end

  def argentina_possible_numbers(clean_number)
    return [] unless clean_number.start_with?('54')

    possible_number =
      if clean_number.start_with?('549')
        clean_number.sub(/^549/, '54')
      else
        clean_number.sub(/^54/, '549')
      end

    [possible_number]
  end

  def find_normalizer_for_country(waid)
    NORMALIZERS.map(&:new)
               .find { |normalizer| normalizer.handles_country?(waid) }
  end

  def find_existing_contact_inbox(normalized_waid)
    inbox.contact_inboxes.find_by(source_id: normalized_waid)
  end

  # Extract clean number from provider-specific format
  def extract_clean_number(raw_number, provider)
    case provider
    when :twilio
      raw_number.gsub(/^whatsapp:\+/, '') # Remove prefix: "whatsapp:+5541988887777" → "5541988887777"
    else
      raw_number # Default fallback for unknown providers
    end
  end

  # Format normalized number for provider-specific storage
  def format_for_provider(clean_number, provider)
    case provider
    when :twilio
      "whatsapp:+#{clean_number}" # Add prefix: "5541988887777" → "whatsapp:+5541988887777"
    else
      clean_number # Default for :cloud and unknown providers: "5541988887777"
    end
  end

  NORMALIZERS = [
    Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer,
    Whatsapp::PhoneNormalizers::ArgentinaPhoneNormalizer
  ].freeze
end
