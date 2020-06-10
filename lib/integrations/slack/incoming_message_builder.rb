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
    SUPPORTED_MESSAGE_TYPES.include?(message[:type])
  end

  def hook_verification?
    params[:type] == 'url_verification'
  end

  def create_message?
    supported_message? && integration_hook
  end

  def message
    params[:event][:blocks].first
  end

  def verify_hook
    {
      challenge: params[:challenge]
    }
  end

  def integration_hook
    @integration_hook ||= Integrations::Hook.where(reference_id: params[:event][:channel])
  end

  def conversation
    @conversation ||= Conversation.where(identifier: params[:event][:thread_ts]).first
  end

  def create_message
    return unless conversation

    conversation.messages.create(
      message_type: 0,
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      content: message[:elements].first[:elements].first[:text]
    )

    { status: 'success' }
  end
end
