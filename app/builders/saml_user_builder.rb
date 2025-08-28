class SamlUserBuilder
  def initialize(auth_hash, account_id: nil)
    @auth_hash = auth_hash
    @account_id = account_id
  end

  def perform
    @user = find_or_create_user
    add_user_to_account if @user.persisted? && @account_id
    @user
  end

  private

  def find_or_create_user
    user = User.from_email(email)

    if user
      convert_existing_user_to_saml(user)
      return user
    end

    create_user
  end

  def convert_existing_user_to_saml(user)
    return if user.saml_user?

    user.convert_to_saml!
  end

  def create_user
    user = User.new(user_params)

    update_display_name(user) if user.save

    user
  end

  def user_params
    {
      email: email,
      name: name,
      provider: 'saml',
      uid: uid,
      password: SecureRandom.hex(32),
      confirmed_at: Time.current
    }
  end

  def update_display_name(user)
    display_name = [first_name, last_name].compact.join(' ')
    user.update(display_name: display_name) if display_name.present?
  end

  def add_user_to_account
    account = Account.find_by(id: @account_id)
    return unless account

    # Create account_user if not exists
    account_user = AccountUser.find_or_create_by(
      user: @user,
      account: account
    )

    # Set default role as agent if not set
    account_user.update(role: 'agent') if account_user.role.blank?

    # Handle role mappings if configured
    apply_role_mappings(account_user, account)
  end

  def apply_role_mappings(account_user, account)
    return if saml_groups.blank?

    saml_settings = AccountSamlSettings.find_by(account_id: account.id, enabled: true)
    return if saml_settings&.role_mappings.blank?

    saml_settings.role_mappings.each do |group_name, mapping|
      next unless saml_groups.include?(group_name)

      if mapping['role'].present?
        account_user.update(role: mapping['role'])
        break # Apply first matching role
      elsif mapping['custom_role_id'].present?
        account_user.update(custom_role_id: mapping['custom_role_id'])
        break # Apply first matching role
      end
    end
  end

  def email
    @auth_hash.dig('info', 'email')
  end

  def name
    @auth_hash.dig('info', 'name') || email.split('@').first
  end

  def first_name
    @auth_hash.dig('info', 'first_name')
  end

  def last_name
    @auth_hash.dig('info', 'last_name')
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
