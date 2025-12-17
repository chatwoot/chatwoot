# The AgentBuilder class is responsible for creating a new agent.
# It initializes with necessary attributes and provides a perform method
# to create a user and account user in a transaction.
class AgentBuilder
  # Initializes an AgentBuilder with necessary attributes.
  pattr_initialize [
    { email: nil },
    { name: '' },
    :inviter,
    :account,
    { role: :agent },
    { availability: :offline },
    { auto_offline: false },
    { is_ai: false },
    :ai_agent_id,
    :agent_key,
    :human_agent_id
  ]

  # Creates a user and account user in a transaction.
  # @return [User] the created user.
  def perform
    ActiveRecord::Base.transaction do
      @user = is_ai ? create_ai_agent : create_human_agent
      create_account_user
    end
    @user
  end

  private

  # Creates a human agent user.
  # @return [User] the found or created user.
  def create_human_agent
    user = User.from_email(email)
    return user if user

    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    @user = User.create!(email: email, name: name, password: temp_password, password_confirmation: temp_password)

    if @user
      # Prepare data for ALOOSTUDIO webhook
      first_name, last_name = (name || '').split(' ', 2)
      payload = {
        firstName: first_name,
        lastName: last_name,
        email: email,
        password: temp_password,
        companyName: account.name
      }
      webhook_url = ENV.fetch('ALOOSTUDIO_WEBHOOK_URL', nil)
      api_token = ENV.fetch('ALOOSTUDIO_API_TOKEN', nil)
      webhook_response = nil
      begin
        conn = Faraday.new do |f|
          f.options.timeout = 60
          f.options.open_timeout = 60
          f.request :json
          f.response :json
          f.adapter Faraday.default_adapter
        end
        response = conn.post(webhook_url, payload) do |req|
          req.headers['x-api-token'] = api_token
          req.headers['Content-Type'] = 'application/json'
        end
        webhook_response = response.body
        Rails.logger.info("ALOOSTUDIO webhook response: #{webhook_response}")
        @user.update(clerk_user_id: webhook_response.dig('clerkId')) if webhook_response.dig('clerkId')
        # Send welcome email separately
        begin
          UserNotifications::AccountMailer.welcome_to_aloostudio_with_password(@user, temp_password).deliver_later
        rescue StandardError => e
          Rails.logger.error("Failed to send welcome email: #{e.message}")
        end
      rescue StandardError => e
        Rails.logger.error("ALOOSTUDIO webhook call failed: #{e.message}")
      end
    end
    @user
  end

  # Creates an AI agent user.
  # @return [User] the created AI user.
  def create_ai_agent
    # Use provided email or generate a unique, non-routable email for the AI agent
    domain = account.domain.presence || 'mg.aloochat.ai'
    ai_email = email.presence || "ai-agent-#{ai_agent_id}@#{domain}"
    Rails.logger.info "[AgentBuilder#create_ai_agent] Attempting to create AI agent with email: #{ai_email}"

    # Check if AI agent with this email already exists
    existing_user = User.find_by(email: ai_email, is_ai: true)
    if existing_user
      Rails.logger.info "[AgentBuilder#create_ai_agent] AI agent with email #{ai_email} already exists, updating and returning existing user"
      # Update existing user with latest information
      existing_user.update!(
        name: name,
        agent_key: agent_key,
        human_agent_id: human_agent_id
      )
      return existing_user
    end

    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    user = User.new(
      email: ai_email,
      name: name,
      password: temp_password,
      password_confirmation: temp_password,
      is_ai: true,
      agent_key: agent_key,
      human_agent_id: human_agent_id
    )
    # AI agents don't need to confirm their email
    user.skip_confirmation!
    user.save!
    user
  end

  # Checks if the user needs confirmation.
  # @return [Boolean] true if the user is persisted and not confirmed, false otherwise.
  def user_needs_confirmation?
    # AI agents are confirmed automatically
    return false if is_ai

    @user.persisted? && !@user.confirmed?
  end

  # Creates an account user linking the user to the current account.
  def create_account_user
    # Check if account_user already exists
    account_user = AccountUser.find_by(account_id: account.id, user_id: @user.id)
    if account_user
      Rails.logger.info "[AgentBuilder#create_account_user] AccountUser already exists for user #{@user.id} in account #{account.id}, updating"
      account_user.update!({
        role: role,
        availability: availability,
        auto_offline: auto_offline
      }.compact)
      return account_user
    end

    AccountUser.create!({
      account_id: account.id,
      user_id: @user.id,
      inviter_id: inviter&.id
    }.merge({
      role: role,
      availability: availability,
      auto_offline: auto_offline
    }.compact))
  end
end

AgentBuilder.prepend_mod_with('AgentBuilder')
