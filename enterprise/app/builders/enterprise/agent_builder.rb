module Enterprise::AgentBuilder
  def perform
    validate_saml_invitation!

    super.tap do |user|
      convert_to_saml_provider(user) if user.persisted? && account.saml_enabled?
    end
  end

  private

  def validate_saml_invitation!
    return unless account.saml_enabled?

    existing_user = User.from_email(email)
    return unless existing_user
    return unless existing_user.account_users.where.not(account_id: account.id).exists?

    existing_user.errors.add(:base, I18n.t('errors.saml.multi_account_invitation_not_allowed'))
    raise ActiveRecord::RecordInvalid, existing_user
  end

  def convert_to_saml_provider(user)
    user.update!(provider: 'saml') unless user.provider == 'saml'
  end
end
