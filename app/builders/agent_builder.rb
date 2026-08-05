# The AgentBuilder class is responsible for creating a new agent.
# It initializes with necessary attributes and provides a perform method
# to create a user and account user in a transaction.
class AgentBuilder
  LIMIT_EXCEEDED_MESSAGE = 'Account limit exceeded. Please purchase more licenses'.freeze

  class LimitExceededError < StandardError
    def initialize
      super(AgentBuilder::LIMIT_EXCEEDED_MESSAGE)
    end
  end

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
    account.with_lock do
      raise LimitExceededError unless can_add_agent?

      ActiveRecord::Base.transaction(requires_new: true) do
        @user = find_or_create_user
        create_account_user
        reserve_invitation_email_capacity if user_needs_confirmation?
      end
    end
    @user.send_confirmation_instructions if user_needs_confirmation?
    @user
  end

  private

  def can_add_agent?
    account.usage_limits[:agents] > account.account_users.count
  end

  # Finds a user by email or creates a new one with a temporary password.
  # @return [User] the found or created user.
  def find_or_create_user
    @new_user = false
    user = User.from_email(email)
    return user if user

    @name = email.split('@').first if @name.blank?
    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    User.new(email: email, name: @name, password: temp_password, password_confirmation: temp_password).tap do |new_user|
      new_user.skip_confirmation_notification!
      new_user.save!
      @new_user = true
    end
  end

  # Checks if the user needs confirmation.
  # @return [Boolean] true if the user is persisted and not confirmed, false otherwise.
  def user_needs_confirmation?
    @new_user && @user.persisted? && !@user.confirmed?
  end

  def reserve_invitation_email_capacity
    return if account.reserve_email_send_capacity

    raise CustomExceptions::Account::EmailLimitExceeded.new({})
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
