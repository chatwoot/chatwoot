# frozen_string_literal: true

class Contacts::MergeContactPoints
  pattr_initialize [:base_contact!, :mergee_contact!]

  def perform
    {
      email: primary_email,
      additional_emails: additional_emails,
      phone_number: primary_phone,
      additional_phones: additional_phones
    }
  end

  private

  def primary_email
    normalized_email(
      base_contact.email.presence ||
      mergee_contact.email.presence ||
      base_contact.additional_emails.first ||
      mergee_contact.additional_emails.first
    )
  end

  def additional_emails
    all_emails - [primary_email]
  end

  def all_emails
    [
      base_contact.email,
      *base_contact.additional_emails,
      mergee_contact.email,
      *mergee_contact.additional_emails
    ].compact_blank.filter_map { |email| normalized_email(email) }.uniq
  end

  def primary_phone
    normalized_phone(
      base_contact.phone_number.presence ||
      mergee_contact.phone_number.presence ||
      base_contact.additional_phones.first ||
      mergee_contact.additional_phones.first
    )
  end

  def additional_phones
    all_phones - [primary_phone]
  end

  def all_phones
    [
      base_contact.phone_number,
      *base_contact.additional_phones,
      mergee_contact.phone_number,
      *mergee_contact.additional_phones
    ].compact_blank.filter_map { |phone| normalized_phone(phone) }.uniq
  end

  def normalized_email(value)
    value.to_s.strip.downcase.presence
  end

  def normalized_phone(value)
    value.to_s.strip.presence
  end
end
