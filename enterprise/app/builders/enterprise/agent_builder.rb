module Enterprise::AgentBuilder
  def perform
    super.tap do |user|
      convert_to_saml_provider(user) if user.persisted? && account.saml_enabled?
    end
  end

  private

  def convert_to_saml_provider(user)
    user.update!(provider: 'saml') unless user.provider == 'saml'
  end
end
