class Saml::UpdateAccountUsersProviderJob < ApplicationJob
  queue_as :default

  # Updates the authentication provider for users in an account
  # This job is triggered when SAML settings are created or destroyed
  def perform(account_id, provider)
    account = Account.find(account_id)
    users_for_provider_update(account, provider).find_each(batch_size: 1000) do |user|
      next unless should_update_user_provider?(account, user, provider)

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:provider, provider)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  private

  def should_update_user_provider?(account, user, provider)
    return !user_has_other_saml_accounts?(user) if provider == 'email'

    account.saml_settings&.trusted_by_accounts_of?(user)
  end

  def users_for_provider_update(account, provider)
    return account.users.where(provider: 'saml') if provider == 'email'

    account.users
  end

  # Checks if the user belongs to any other accounts that have SAML configured
  # Used to preserve SAML authentication when one account disables SAML but others still use it
  def user_has_other_saml_accounts?(user)
    user.accounts.joins(:saml_settings).exists?
  end
end
