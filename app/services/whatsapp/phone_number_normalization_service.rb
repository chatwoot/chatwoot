# Service to handle phone number normalization for WhatsApp messages
# Currently supports Brazil, Argentina, and Mexico phone number format variations
# Supports both WhatsApp Cloud API and Twilio WhatsApp providers
class Whatsapp::PhoneNumberNormalizationService
  def initialize(inbox)
    @inbox = inbox
  end

  # @param raw_number [String] The phone number in provider-specific format
  #   - Cloud: "5541988887777" (clean number)
  #   - Twilio: "whatsapp:+5541988887777" (prefixed format)
  # @param provider [Symbol] :cloud or :twilio
  # @return [String] Normalized source_id in provider format or original if not found
  def normalize_and_find_contact_by_provider(raw_number, provider)
    # Extract clean number based on provider format
    clean_number = extract_clean_number(raw_number, provider)

    # Find appropriate normalizer for the country
    normalizer = find_normalizer_for_country(clean_number)
    return raw_number unless normalizer

    # The contact may already be stored under any of the country's equivalent formats
    existing_contact_inbox = normalizer.variants(clean_number).lazy
                                       .filter_map { |number| find_existing_contact_inbox(format_for_provider(number, provider)) }
                                       .first

    existing_contact_inbox&.source_id || raw_number
  end

  # Keep the provider value first so exact contact matches always win. Each
  # country normalizer explicitly opts into contact-safe alternatives; source-id
  # normalization alone is not enough because the alternate may be another
  # valid number (for example an Argentina landline without the mobile 9).
  def phone_number_candidates(clean_number)
    normalizer = find_normalizer_for_country(clean_number)
    return [clean_number] unless normalizer

    normalizer.contact_candidates(clean_number)
  end

  private

  attr_reader :inbox

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
    Whatsapp::PhoneNormalizers::ArgentinaPhoneNormalizer,
    Whatsapp::PhoneNormalizers::MexicoPhoneNormalizer
  ].freeze
end
