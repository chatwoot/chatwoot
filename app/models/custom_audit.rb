class CustomAudit < Audited::Audit
  after_save :log_additional_information

  private

  def log_additional_information
    update_columns(username: user.email)
  end
end
