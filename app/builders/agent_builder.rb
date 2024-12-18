# The AgentBuilder class is responsible for creating a new agent.
# It initializes with necessary attributes and provides a perform method
# to create a user and account user in a transaction.
class AgentBuilder
  # Initializes an AgentBuilder with necessary attributes.
  # @param email [String] the email of the user.
  # @param name [String] the name of the user.
  # @param role [String] the role of the user, defaults to 'agent' if not provided.
  # @param inviter [User] the user who is inviting the agent (Current.user in most cases).
  # @param availability [String] the availability status of the user, defaults to 'offline' if not provided.
  # @param auto_offline [Boolean] the auto offline status of the user.
  pattr_initialize [:email, { name: '' }, :inviter, :account, { role: :agent }, { availability: :offline }, { auto_offline: false }]

  # Creates a user and account user in a transaction.
  # @return [User] the created user.
  def perform
    ActiveRecord::Base.transaction do
      @user = find_or_create_user
      create_account_user
      create_user_on_keycloak
    end
    @user
  end

  private

  # Finds a user by email or creates a new one with a temporary password.
  # @return [User] the found or created user.
  def find_or_create_user
    user = User.from_email(email)
    return user if user

    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    User.create!(email: email, name: name, password: temp_password, password_confirmation: temp_password)
  end

  # Checks if the user needs confirmation.
  # @return [Boolean] true if the user is persisted and not confirmed, false otherwise.
  def user_needs_confirmation?
    @user.persisted? && !@user.confirmed?
  end

  # Creates an account user linking the user to the current account.
  def create_account_user
    AccountUser.create!({
      account_id: account.id,
      user_id: @user.id,
      inviter_id: inviter.id
    }.merge({
      role: role,
      availability: availability,
      auto_offline: auto_offline
    }.compact))
  end

  def get_keycloak_admin_accesss_token
    realm = ENV.fetch('KEYCLOAK_REALM', nil)
    keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
    token_url = URI.join(keycloak_url, "/realms/#{realm}/protocol/openid-connect/token").to_s
    client_id = ENV.fetch('KEYCLOAK_CLIENT_ID', nil)
    client_secret = ENV.fetch('KEYCLOAK_CLIENT_SECRET', nil)

    token_response = HTTParty.post(
      token_url, {
        body: {
          grant_type: 'client_credentials',
          client_id: client_id,
          client_secret: client_secret
        },
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      }
    )

    return nil unless token_response.success?

    token_response.parsed_response['access_token']
  end

  def create_user_on_keycloak
    access_token = get_keycloak_admin_accesss_token
    return unless access_token

    realm = ENV.fetch('KEYCLOAK_REALM', nil)
    keycloak_url = ENV.fetch('KEYCLOAK_URL', nil)
    user_url = URI.join(keycloak_url, "admin/realms/#{realm}/users").to_s
    temp_password = generate_temp_password
    user_response = HTTParty.post(
      user_url, {
        body: {
          email: email,
          enabled: true,
          emailVerified: true,
          credentials: [
            {
              type: 'password',
              value: temp_password,
              temporary: true
            }
          ]
        }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{access_token}"
        }
      }
    )

    if user_response.success?
      @user.custom_attributes['keycloak_temp_password'] = temp_password
      @user.save!
    else
      @user.custom_attributes['user_on_keycloak'] = true
      @user.save!
    end
  end

  def generate_temp_password
    special_characters = ['@', '#', '$', '%', '&', '*', '!', '^', '+', '-', '_']

    haiku_part = Haikunator.haikunate
    base_password = haiku_part.gsub(/[^A-Za-z]/, '')
    base_password += SecureRandom.random_number(10).to_s
    base_password += ('A'..'Z').to_a.sample
    base_password += special_characters.sample
    password = base_password.chars.shuffle.join

    password += SecureRandom.hex(1) while password.length < 12

    password.chars.shuffle.join
  end
end
