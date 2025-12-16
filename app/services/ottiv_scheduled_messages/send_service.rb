class OttivScheduledMessages::SendService
  attr_reader :scheduled_message

  def initialize(scheduled_message)
    @scheduled_message = scheduled_message
  end

  def perform
    ActiveRecord::Base.transaction do
      message = send_message
      update_scheduled_message_status
      create_next_occurrence_if_recurrent
      create_occurrence_record(message)
      message
    end
  rescue StandardError => e
    handle_error(e)
    raise e
  end

  private

  def send_message
    conversation = scheduled_message.conversation
    user = scheduled_message.creator

    message_params = build_message_params
    builder = Messages::MessageBuilder.new(user, conversation, message_params)
    message = builder.perform

    # Mark message as scheduled
    message.update!(
      additional_attributes: (message.additional_attributes || {}).merge(is_scheduled: true)
    )

    message
  end

  def build_message_params
    params = ActionController::Parameters.new({
      content: scheduled_message.content,
      message_type: 'outgoing',
      private: false
    })

    # Add content_type based on message_type
    case scheduled_message.message_type
    when 'text'
      params[:content_type] = :text
    when 'media'
      params[:content_type] = :text
      # Media URL handling would be done via attachments
    when 'audio'
      params[:content_type] = :text
      # Audio URL handling would be done via attachments
    when 'quick_reply'
      params[:content_type] = :text
      # Quick reply handling would be done via content_attributes
    end

    params
  end

  def update_scheduled_message_status
    scheduled_message.mark_as_sent!
  end

  def create_next_occurrence_if_recurrent
    return unless scheduled_message.has_recurrence?

    next_send_at = calculate_next_send_at
    return if next_send_at.nil?

    # Create new scheduled message for next occurrence
    OttivScheduledMessage.create!(
      title: scheduled_message.title,
      message_type: scheduled_message.message_type,
      content: scheduled_message.content,
      media_url: scheduled_message.media_url,
      audio_url: scheduled_message.audio_url,
      quick_reply_id: scheduled_message.quick_reply_id,
      account_id: scheduled_message.account_id,
      conversation_id: scheduled_message.conversation_id,
      contact_id: scheduled_message.contact_id,
      send_at: next_send_at,
      timezone: scheduled_message.timezone,
      recurrence: scheduled_message.recurrence,
      status: :scheduled,
      created_by: scheduled_message.created_by
    )
  end

  def calculate_next_send_at
    current_send_at = @scheduled_message.send_at
    
    case @scheduled_message.recurrence.to_sym
    when :daily
      current_send_at + 1.day
    when :weekly
      current_send_at + 1.week
    when :biweekly
      current_send_at + 2.weeks
    when :monthly
      current_send_at + 1.month
    when :quarterly
      current_send_at + 3.months
    when :semiannual
      current_send_at + 6.months
    when :annual
      current_send_at + 1.year
    else
      nil # no_recurrence
    end
  end

  def create_occurrence_record(message)
    scheduled_message.ottiv_scheduled_message_occurrences.create!(
      sent_at: Time.current,
      status: :sent
    )
  end

  def handle_error(error)
    scheduled_message.mark_as_failed!(error.message)
  end
end

