# Syncs a student-form submission from Firestore into a Chatwoot contact.
#
# Idempotent on Firestore document id (`student[:id]` → contact.identifier).
# Retries from Firebase Cloud Functions will update the existing contact.
class Integrations::StudentSyncService
  pattr_initialize [:account!, :student!]

  def perform
    validate_payload!
    sync_contact
  end

  private

  def validate_payload!
    raise ArgumentError, 'student id is required' if student_id.blank?
    raise ArgumentError, 'student name is required' if name.blank?
    raise ArgumentError, 'student phone is required' if raw_phone.blank?
    raise ArgumentError, 'student phone is invalid' if phone_number.blank?
  end

  def sync_contact
    contact = find_contact || account.contacts.new(identifier: student_id)

    assign_contact_attributes(contact)
    contact.save!
    contact
  rescue ActiveRecord::RecordNotUnique
    # Concurrent create from a retried Cloud Function event.
    find_contact.tap do |existing|
      raise ActiveRecord::RecordNotFound, 'Contact race unresolved' if existing.blank?

      assign_contact_attributes(existing)
      existing.save!
    end
  end

  def find_contact
    account.contacts.find_by(identifier: student_id) ||
      account.contacts.find_by(phone_number: phone_number)
  end

  def assign_contact_attributes(contact)
    contact.name = name
    contact.phone_number = phone_number
    # Keep an existing identifier if the contact was matched by phone only and
    # already belongs to another external system; otherwise pin to Firestore id.
    contact.identifier = student_id if contact.identifier.blank?
    contact.contact_type = :lead if contact.visitor? || contact.new_record?
    contact.custom_attributes = (contact.custom_attributes || {}).merge(custom_attributes)
    contact.additional_attributes = (contact.additional_attributes || {}).merge(additional_attributes)
  end

  def custom_attributes
    {
      'student_form_id' => student_id,
      'study_division' => study_division,
      'form_type' => form_type,
      'link_code' => link_code,
      'source' => 'student-form'
    }.compact
  end

  def additional_attributes
    attrs = { 'source' => 'student-form' }
    attrs['ip'] = student[:ip].to_s if student[:ip].present?
    attrs
  end

  def student_id
    student[:id].to_s.strip
  end

  def name
    student[:name].to_s.strip
  end

  def study_division
    student[:study_division].to_s.strip.presence
  end

  def form_type
    student[:type].to_s.strip.presence
  end

  def link_code
    student[:link_code].to_s.strip.presence
  end

  def raw_phone
    student[:number_phone].presence || student[:phone].presence
  end

  # Normalizes Algerian form phones (0XXXXXXXXX / +213XXXXXXXXX) to E.164.
  def phone_number
    @phone_number ||= normalize_algerian_phone(raw_phone)
  end

  def normalize_algerian_phone(value)
    digits = value.to_s.gsub(/\D/, '')
    return if digits.blank?

    normalized = if digits.start_with?('213') && digits.length == 12
                   "+#{digits}"
                 elsif digits.start_with?('0') && digits.length == 10
                   "+213#{digits[1..]}"
                 elsif digits.length == 9 && digits.match?(/\A[567]/)
                   "+213#{digits}"
                 elsif value.to_s.start_with?('+')
                   "+#{digits}"
                 else
                   "+#{digits}"
                 end

    normalized.match?(/\A\+[1-9]\d{1,14}\z/) ? normalized : nil
  end
end
