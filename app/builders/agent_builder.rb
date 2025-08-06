# The AgentBuilder class is responsible for creating a new agent.
# It initializes with necessary attributes and provides a perform method
# to create a user and account user in a transaction.
#
# Attributes:
# @param email [String] the email of the user.
# @param name [String] the name of the user.
# @param role [String] the role of the user, defaults to 'agent' if not provided.
# @param inviter [User] the user who is inviting the agent (Current.user in most cases).
# @param availability [String] the availability status of the user, defaults to 'offline' if not provided.
# @param auto_offline [Boolean] the auto offline status of the user.
# @param password [String, nil] the password for the user, optional.
# @param confirmed_at [String, Time, nil] the confirmation timestamp for the user, optional.
class AgentBuilder
  # Initializes an AgentBuilder with necessary attributes.
  pattr_initialize [
    :email!,
    { name: '' },
    :inviter!,
    :account!,
    { role: :agent },
    { availability: :offline },
    { auto_offline: false },
    { password: nil },
    { confirmed_at: nil }
  ]

  def perform
    ActiveRecord::Base.transaction do
      @user = find_or_create_user
      apply_confirmation! if confirmed_at.present? && user_needs_confirmation?
      create_account_user
    end
    @user
  end

  private

  def find_or_create_user
    user = User.from_email(email)
    return user if user

    pwd = password.presence || generate_temp_password
    User.create!(
      email:                 email,
      name:                  name,
      password:              pwd,
      password_confirmation: pwd
    )
  end

  def user_needs_confirmation?
    @user.persisted? && @user.respond_to?(:confirmed?) && !@user.confirmed?
  end

  def apply_confirmation!
    if @user.respond_to?(:confirmed_at=)
      ts = parse_confirmed_at
      @user.update!(confirmed_at: ts)
    else
      @user.confirm
    end
  end
  
  def create_account_user
    base_attrs = {
      account_id: account.id,
      user_id:    @user.id,
      inviter_id: inviter.id
    }
    extra_attrs = {
      role:         role,
      availability: availability,
      auto_offline: auto_offline
    }.compact
    AccountUser.create!(base_attrs.merge(extra_attrs))
  end

  def generate_temp_password
    "1!aA#{SecureRandom.alphanumeric(12)}"
  end

  def parse_confirmed_at
    case confirmed_at
    when String then Time.zone.parse(confirmed_at)
    when Time   then confirmed_at
    else Time.zone.now
    end
  rescue
    Time.zone.now
  end
end
