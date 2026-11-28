# Records which of a contact's values came from a trusted source.
# A mark stays on a value only while that value is the one the trusted source supplied.
module VerifiableAttributes
  extend ActiveSupport::Concern

  VERIFIABLE_ATTRIBUTES = %w[name email phone_number].freeze
  VERIFICATION_SOURCES = %w[jwt].freeze

  included do
    validate :verified_attributes_are_known, if: :will_save_change_to_verified_attributes?
  end

  def attribute_verified?(attribute)
    verified_attributes.key?(attribute.to_s)
  end

  # Writes the values a trusted source vouches for. Their marks are set when the contact is stored.
  def assign_verified_attributes(attributes, source:)
    raise ArgumentError, "Unknown verification source: #{source}" unless VERIFICATION_SOURCES.include?(source)

    trusted_values = attributes.to_h.stringify_keys.slice(*VERIFIABLE_ATTRIBUTES).compact_blank
    # The contact stores emails in lower case, and the mark is set only when the stored value is the trusted one.
    trusted_values['email'] = trusted_values['email'].to_s.downcase if trusted_values.key?('email')
    assign_attributes(trusted_values)

    trusted_values.each_key do |attribute|
      pending_verifications[attribute] = { value: self[attribute], source: source }
    end
  end

  # Contacts::SyncAttributes calls this before a contact is stored.
  def sync_verified_attributes
    return if verified_attributes.blank? && pending_verifications.blank?

    marks = verified_attributes.dup
    VERIFIABLE_ATTRIBUTES.each do |attribute|
      pending_verification = pending_verifications[attribute]

      if pending_verification && pending_verification[:value] == self[attribute]
        marks[attribute] = pending_verification[:source]
      elsif will_save_change_to_attribute?(attribute)
        marks.delete(attribute)
      end
    end

    self.verified_attributes = marks
    pending_verifications.clear
  end

  private

  def pending_verifications
    @pending_verifications ||= {}
  end

  def verified_attributes_are_known
    return if verified_attributes.is_a?(Hash) && verified_attributes.all? { |attribute, source| known_verification?(attribute, source) }

    errors.add(:verified_attributes, I18n.t('errors.contacts.verified_attributes.invalid'))
  end

  def known_verification?(attribute, source)
    VERIFIABLE_ATTRIBUTES.include?(attribute) && VERIFICATION_SOURCES.include?(source)
  end
end
