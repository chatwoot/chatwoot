class Migration::ResetUntrustedSamlUsersJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    User.where(provider: 'saml').includes(accounts: :saml_settings).find_each do |user|
      next if saml_sign_in_possible?(user)

      user.update_column(:provider, 'email') # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  def saml_sign_in_possible?(user)
    user.accounts.any? do |account|
      account.feature_enabled?('saml') && account.saml_settings&.saml_enabled? && account.saml_settings.trusted_by_accounts_of?(user)
    end
  end
end
