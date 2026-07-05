module Custom::Mfa::ManagementService
  # The TOTP issuer is shown as the account label in the user's authenticator
  # app, so it must carry the fork's brand instead of the hardcoded "Chatwoot".
  # Uses the installation name (set by Custom::BrandingSetup / INSTALLATION_NAME)
  # and keeps the upstream default only when branding is unset.
  def two_factor_provisioning_uri
    return nil if user.otp_secret.blank?

    issuer = GlobalConfig.get_value('INSTALLATION_NAME').presence || 'Chatwoot'
    user.otp_provisioning_uri(user.email, issuer: issuer)
  end
end
