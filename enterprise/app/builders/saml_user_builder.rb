class SamlUserBuilder
  def initialize(auth_hash, account_id)
    @auth_hash = auth_hash
    @account_id = account_id
    @saml_settings = AccountSamlSettings.find_by(account_id: account_id)
  end

  def perform
    @user = find_or_create_user
    add_user_to_account if @user.persisted?
    @user
  end

  private

  def find_or_create_user
    user = User.from_email(auth_attribute('email'))

    if user
      confirm_user_if_required(user)
      convert_existing_user_to_saml(user)
      return user
    end

    create_user
  end

  def confirm_user_if_required(user)
    return if user.confirmed?

    user.skip_confirmation!
    user.save!
  end

  def convert_existing_user_to_saml(user)
    return if user.provider == 'saml'

    user.update!(provider: 'saml')
  end

  def create_user
    full_name = [auth_attribute('first_name'), auth_attribute('last_name')].compact.join(' ')
    fallback_name = auth_attribute('name') || auth_attribute('email').split('@').first

    User.create!(
      email: auth_attribute('email'),
      name: (full_name.presence || fallback_name),
      display_name: auth_attribute('first_name'),
      provider: 'saml',
      uid: uid,
      password: SecureRandom.hex(32),
      confirmed_at: Time.current
    )
  end

  def add_user_to_account
    account = Account.find_by(id: @account_id)
    return unless account

    # Create account_user if not exists
    account_user = AccountUser.find_or_create_by!(
      user: @user,
      account: account
    )

    # Set default role as agent if not set
    account_user.update!(role: 'agent') if account_user.role.blank?

    # Handle role mappings if configured
    apply_role_mappings(account_user, account)
  end

  def apply_role_mappings(account_user, account)
    matching_mapping = find_matching_role_mapping(account)
    return unless matching_mapping

    if matching_mapping['role']
      account_user.update!(role: matching_mapping['role'])
    elsif matching_mapping['custom_role_id']
      account_user.update!(custom_role_id: matching_mapping['custom_role_id'])
    end
  end

  def find_matching_role_mapping(_account)
    return if @saml_settings&.role_mappings.blank?

    saml_groups.each do |group|
      mapping = @saml_settings.role_mappings[group]
      return mapping if mapping.present?
    end
    nil
  end

  def auth_attribute(key, fallback = nil)
    @auth_hash.dig('info', key) || fallback
  end

  def uid
    @auth_hash['uid']
  end

  def saml_groups
    # Groups can come from different attributes depending on IdP
    @auth_hash.dig('extra', 'raw_info', 'groups') ||
      @auth_hash.dig('extra', 'raw_info', 'Group') ||
      @auth_hash.dig('extra', 'raw_info', 'memberOf') ||
      []
  end
end
