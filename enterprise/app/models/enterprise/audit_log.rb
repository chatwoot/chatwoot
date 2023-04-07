class Enterprise::AuditLog < Audited::Audit
  after_save :log_additional_information

  private

  def log_additional_information
    # rubocop:disable Rails/SkipsModelValidations
    update_columns(username: user&.email)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
