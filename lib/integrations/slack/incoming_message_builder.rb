class Integrations::Slack::IncomingMessageBuilder
  attr_reader :params

  SUPPORTED_EVENT_TYPES = %w(event_callback url_verification)
  SUPPORTED_EVENTS = %w(message)
  SUPPORTED_MESSAGE_TYPES = %w(rich_text)

  def initialize(params)
    @params = params
  end

  def perform
    return unless supported_event_type?
    return unless supported_event?
    
    if hook_verification?
      verify_hook
    elsif integration_hook
      create_messages
    end
  end

  private

  def supported_event_type?
    SUPPORTED_EVENT_TYPES.include?(params[:type])
  end

  def supported_event?
    hook_verification? || SUPPORTED_EVENTS.include?(params[:event][:type])
  end

  def hook_verification?
    params[:type] = "url_verification"
  end

  def verify_hook
    {
      challenge: params[:challenge]
    }
  end

  def integration_hook
    @hook ||= Integrations::Hook.where(reference_id: params[:event][:channel])
  end

  def conversation
    # find conversation by thread_id
  end

  def create_message
    # create message
  end
end