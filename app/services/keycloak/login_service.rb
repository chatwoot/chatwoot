# Finds (or provisions) the Chatwoot user for a Keycloak login and syncs their roles into account permissions.
class Keycloak::LoginService
  class LoginError < StandardError; end

  def initialize(auth_hash)
    @auth_hash = auth_hash
    @email = auth_hash.dig('info', 'email').to_s.downcase
  end

  def perform
    raise LoginError, 'email-missing' if @email.blank?
    raise LoginError, 'email-not-verified' unless email_verified?

    roles = Keycloak::RoleExtractor.new(@auth_hash).roles
    raise LoginError, 'no-chatwoot-role' if require_role? && Keycloak::PermissionMap.resolve(roles).nil?

    user = User.from_email(@email) || provision_user
    Keycloak::RoleSyncService.new(user: user, keycloak_roles: roles).perform
    user
  end

  private

  # Only members that were explicitly given a chatwoot_* role in Keycloak may log in (default on).
  def require_role?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('KEYCLOAK_REQUIRE_ROLE', 'true'))
  end

  # MIS members are provisioned by admins and their emails are not verified in Keycloak.
  def email_verified?
    return true if ActiveModel::Type::Boolean.new.cast(ENV.fetch('KEYCLOAK_TRUST_UNVERIFIED_EMAIL', 'false'))

    ActiveModel::Type::Boolean.new.cast(@auth_hash.dig('info', 'email_verified') || @auth_hash.dig('extra', 'raw_info', 'email_verified'))
  end

  def provision_user
    account = target_account
    raise LoginError, 'no-account-found' if account.nil?

    user = User.new(email: @email, name: @auth_hash.dig('info', 'name').presence || @email.split('@').first,
                    password: "#{SecureRandom.hex(16)}aA1!", confirmed_at: Time.current)
    user.save!
    AccountUser.create!(account: account, user: user, role: :agent)
    user
  end

  def target_account
    id = ENV.fetch('KEYCLOAK_ACCOUNT_ID', nil)
    id.present? ? Account.find_by(id: id) : Account.order(:id).first
  end
end
