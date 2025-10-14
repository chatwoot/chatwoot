# Service to handle phone number normalization for WhatsApp messages
# Currently supports Brazil and Argentina phone number format variations
# Designed to be extensible for additional countries in future PRs
#
# Usage: Whatsapp::PhoneNumberNormalizationService.new(inbox).normalize_and_find_contact(waid)
class Whatsapp::PhoneNumberNormalizationService
  def initialize(inbox)
    @inbox = inbox
  end

  # Main entry point for phone number normalization
  # Returns the source_id of an existing contact if found, otherwise returns original waid
  def normalize_and_find_contact(waid)
    normalizer = find_normalizer_for_country(waid)
    return waid unless normalizer

    normalized_waid = normalizer.normalize(waid)
    existing_contact_inbox = find_existing_contact_inbox(normalized_waid)

    existing_contact_inbox&.source_id || waid
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

  NORMALIZERS = [
    Whatsapp::PhoneNormalizers::BrazilPhoneNormalizer,
    Whatsapp::PhoneNormalizers::ArgentinaPhoneNormalizer
  ].freeze
end
