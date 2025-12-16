class OttivScheduledMessages::CreateService
  attr_reader :params, :user, :account

  def initialize(params:, user:, account:)
    @params = params
    @user = user
    @account = account
  end

  def perform
    validate_params!
    create_scheduled_message
  end

  private

  def create_scheduled_message
    scheduled_message = OttivScheduledMessage.new(scheduled_message_params)
    scheduled_message.account = account
    scheduled_message.creator = user
    scheduled_message.status = :scheduled
    scheduled_message.save!
    scheduled_message
  end

  def validate_params!
    raise ArgumentError, 'conversation_id is required' if params[:conversation_id].blank?
    raise ArgumentError, 'send_at must be in the future' if params[:send_at].present? && Time.parse(params[:send_at].to_s) <= Time.current
    raise ArgumentError, 'message_type is required' if params[:message_type].blank?
  end

  def scheduled_message_params
    params.permit(
      :title,
      :message_type,
      :content,
      :media_url,
      :audio_url,
      :quick_reply_id,
      :conversation_id,
      :contact_id,
      :send_at,
      :timezone,
      :recurrence
    )
  end
end

