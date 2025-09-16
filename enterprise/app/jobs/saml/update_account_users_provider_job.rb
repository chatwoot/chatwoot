class Saml::UpdateAccountUsersProviderJob < ApplicationJob
  queue_as :default

  # Updates the authentication provider for users in an account
  # This job is triggered when SAML settings are created or destroyed
  def perform(account_id, provider)
    account = Account.find(account_id)
    account.users.find_each(batch_size: 1000) do |user|
      next unless should_update_user_provider?(user, provider)

      # rubocop:disable Rails/SkipsModelValidations
      user.update_column(:provider, provider)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  private

  # Determines if a user's provider should be updated based on their multi-account status
  # When resetting to 'email', only update users who don't have SAML enabled on other accounts
  # This prevents breaking SAML authentication for users who belong to multiple accounts
  def should_update_user_provider?(user, provider)
    return !user_has_other_saml_accounts?(user) if provider == 'email'

    true
  end

  # Checks if the user belongs to any other accounts that have SAML configured
  # Used to preserve SAML authentication when one account disables SAML but others still use it
  def user_has_other_saml_accounts?(user)
    user.accounts.joins(:saml_settings).exists?
  end
end
