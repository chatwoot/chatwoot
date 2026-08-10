module Enterprise::AgentBuilder
  def perform
    super.tap do |user|
      # Never flip an existing user's provider just by inviting them.
      convert_to_saml_provider(user) if user.persisted? && new_user? && account.saml_enabled?
    end
  end

  private

  # uid stays pending until their first real SAML login binds it.
  def convert_to_saml_provider(user)
    user.update!(provider: 'saml', uid: user.pending_saml_uid) unless user.provider == 'saml'
  end
end
