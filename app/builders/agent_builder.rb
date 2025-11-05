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
  # @param password [String] the password for the new user (optional, generates random if not provided).
  # @param password_confirmation [String] the password confirmation.
  pattr_initialize [:email, { name: '' }, :inviter, :account, { role: :agent }, { availability: :offline }, { auto_offline: false }, :password,
                    :password_confirmation]

  # Creates a user and account user in a transaction.
  # @return [User] the created user.
  def perform
    ActiveRecord::Base.transaction do
      @user = find_or_create_user
      create_account_user
    end
    @user
  end

  private

  # Finds a user by email or creates a new one with provided or temporary password.
  # @return [User] the found or created user.
  def find_or_create_user
    user = User.from_email(email)
    return user if user

    # Use provided password or generate a temporary one
    user_password = (password.presence || "1!aA#{SecureRandom.alphanumeric(12)}")
    user_password_confirmation = (password_confirmation.presence || user_password)

    # Create user - skip email format validation
    # Devise validatable validates email format, so we use validate: false
    user = User.new(
      email: email,
      name: name,
      password: user_password,
      password_confirmation: user_password_confirmation
    )

    # Set uid for Devise Token Auth (required)
    user.uid = email

    # Save without validations (bypasses Devise email format validation)
    # Password will still be encrypted by Devise callbacks
    user.save(validate: false)

    # Skip email confirmation so user can login immediately
    user.skip_confirmation!
    user.save(validate: false)

    user
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
end

AgentBuilder.prepend_mod_with('AgentBuilder')
