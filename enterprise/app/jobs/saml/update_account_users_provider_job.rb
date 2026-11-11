class Saml::UpdateAccountUsersProviderJob < ApplicationJob
  queue_as :default

  # Updates the authentication provider for users in an account
  # This job is triggered when SAML settings are created or destroyed
  def perform(account_id, provider)
    account = Account.find(account_id)
    return if provider == 'email' && account.saml_settings.present?

    users_for_provider_update(account, provider).find_each(batch_size: 1000) do |user|
      next if provider == 'saml' && !account.saml_settings&.trusted_by_accounts_of?(user)

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:provider, provider)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  private

  def users_for_provider_update(account, provider)
    return account.users.where(provider: 'saml') if provider == 'email'

    account.users
  end
end
