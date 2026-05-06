module ContactPointable
  extend ActiveSupport::Concern

  included do
    has_many :contact_emails, dependent: :destroy
    has_many :contact_phones, dependent: :destroy

    before_destroy :snapshot_contact_points_for_destroy, prepend: true
    validate :email_not_used_as_additional
    validate :phone_number_not_used_as_additional
  end

  def additional_emails
    return contact_emails.sort_by(&:id).map(&:email) if contact_emails.loaded?

    contact_emails.order(:id).pluck(:email)
  end

  def additional_phones
    return contact_phones.sort_by(&:id).map(&:phone_number) if contact_phones.loaded?

    contact_phones.order(:id).pluck(:phone_number)
  end

  def all_emails
    contact_point_data[:email_addresses]
  end

  def all_phone_numbers
    contact_point_data[:phone_numbers]
  end

  def contact_point_data
    additional_email_values = additional_emails
    additional_phone_values = additional_phones

    {
      additional_emails: additional_email_values,
      email_addresses: [email, *additional_email_values].compact_blank,
      additional_phones: additional_phone_values,
      phone_numbers: [phone_number, *additional_phone_values].compact_blank
    }
  end

  private

  def email_not_used_as_additional
    return if email.blank? || account_id.blank?
    return unless ContactEmail.exists?(account_id: account_id, email: email.downcase)

    errors.add(:email, :taken)
  end

  def phone_number_not_used_as_additional
    return if phone_number.blank? || account_id.blank?
    return unless ContactPhone.exists?(account_id: account_id, phone_number: phone_number)

    errors.add(:phone_number, :taken)
  end

  def destroyed_contact_point_data
    @destroyed_contact_point_data || contact_point_data
  end

  def snapshot_contact_points_for_destroy
    @destroyed_contact_point_data = contact_point_data
  end
end
