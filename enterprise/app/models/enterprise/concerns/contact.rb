module Enterprise::Concerns::Contact
  extend ActiveSupport::Concern
  included do
    belongs_to :company, optional: true, counter_cache: true

    after_commit :associate_company_from_email,
                 on: [:create, :update],
                 if: :should_associate_company?
  end

  private

  def should_associate_company?
    return false if email.blank? || company_id.present?

    saved_change_to_email? || saved_change_to_additional_attributes? || saved_change_to_phone_number?
  end

  def associate_company_from_email
    Contacts::CompanyAssociationService.new.associate_company_from_email(self)
  rescue StandardError => e
    Rails.logger.error("Failed to associate company for contact #{id}: #{e.message}")
    # Don't fail the contact save if the company association fails
  end
end
