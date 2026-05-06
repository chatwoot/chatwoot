module Enterprise::ContactMergeAction
  private

  def sync_merged_contact_emails!
    should_associate_company_after_merge = base_contact.company_id.nil? && base_contact.email.blank?

    super

    return unless should_associate_company_after_merge
    return if base_contact.company_id.present? || base_contact.email.blank?

    Contacts::CompanyAssociationService.new.associate_company_from_email(base_contact)
  end
end
