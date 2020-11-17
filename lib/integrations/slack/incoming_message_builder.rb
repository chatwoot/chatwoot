class Integrations::Slack::IncomingMessageBuilder
  attr_reader :params

  SUPPORTED_EVENT_TYPES = %w[event_callback url_verification].freeze
  SUPPORTED_EVENTS = %w[message].freeze
  SUPPORTED_MESSAGE_TYPES = %w[rich_text].freeze

  def initialize(params)
    @params = params
  end

  def perform
    return unless valid_event?

    if hook_verification?
      verify_hook
    elsif create_message?
      create_message
    end
  end

  private

  def valid_event?
    supported_event_type? && supported_event?
  end

  def supported_event_type?
    SUPPORTED_EVENT_TYPES.include?(params[:type])
  end

  def supported_event?
    hook_verification? || SUPPORTED_EVENTS.include?(params[:event][:type])
  end

  def supported_message?
    SUPPORTED_MESSAGE_TYPES.include?(message[:type]) if message.present?
  end

  def hook_verification?
    params[:type] == 'url_verification'
  end

  def thread_timestamp_available?
    params[:event][:thread_ts].present?
  end

  def create_message?
    thread_timestamp_available? && supported_message? && integration_hook
  end

  def message
    params[:event][:blocks]&.first
  end

  def verify_hook
    {
      challenge: params[:challenge]
    }
  end

  def integration_hook
    @integration_hook ||= Integrations::Hook.find_by(reference_id: params[:event][:channel])
  end

  def conversation
    @conversation ||= Conversation.where(identifier: params[:event][:thread_ts]).first
  end

  def sender
    user_email = slack_client.users_info(user: params[:event][:user])[:user][:profile][:email]
    conversation.account.users.find_by(email: user_email)
  end

  def private_note?
    params[:event][:text].strip.starts_with?('note:', 'private:')
  end

  def create_message
    return unless conversation

    conversation.messages.create(
      message_type: :outgoing,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: params[:event][:text],
      external_source_id_slack: params[:event][:ts],
      private: private_note?,
      sender: sender
    )

    { status: 'success' }
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: @integration_hook.access_token)
  end
end
