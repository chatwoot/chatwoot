class Enterprise::AuditLog < Audited::Audit
  after_save :log_additional_information

  private

  def log_additional_information
    # rubocop:disable Rails/SkipsModelValidations
    if auditable_type == 'Account' && auditable_id.present?
      update_columns(associated_type: auditable_type, associated_id: auditable_id, username: user&.email)
    else
      update_columns(username: user&.email)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
