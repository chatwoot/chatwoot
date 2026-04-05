class ConversationDrop < BaseDrop
  include MessageFormatHelper

  def display_id
    @obj.try(:display_id)
  end

  def contact_name
    @obj.try(:contact).name.try(:capitalize) || 'Customer'
  end

  def recent_messages
    @obj.try(:recent_messages).map do |message|
      {
        'sender' => message_sender_name(message.sender),
        'content' => render_message_content(transform_user_mention_content(message.content)),
        'attachments' => message.attachments.map(&:file_url)
      }
    end
  end

  def custom_attribute
    custom_attributes = @obj.try(:custom_attributes) || {}
    custom_attributes.transform_keys(&:to_s)
  end

  def queue_position
    return 0 unless @obj.open?
    return 0 if @obj.assignee_id.present?

    @obj.inbox.conversations.open.unassigned.count
  end

  def avg_wait_time_seconds
    avg_first_response_seconds
  end

  def avg_wait_time_minutes
    secs = avg_first_response_seconds
    return 0 if secs.zero?

    (secs / 60.0).ceil
  end

  private

  def avg_first_response_seconds
    @avg_first_response_seconds ||= fetch_avg_first_response_seconds
  end

  def fetch_avg_first_response_seconds
    account = @obj.account
    tz = ActiveSupport::TimeZone[account.reporting_timezone] || Time.zone
    today_range = tz.now.beginning_of_day..tz.now
    result = account.reporting_events
                    .where(
                      name: 'first_response',
                      inbox_id: @obj.inbox_id,
                      created_at: today_range
                    )
                    .average(:value)
    (result || 0).to_i
  end

  def message_sender_name(sender)
    return 'Bot' if sender.blank?
    return contact_name if sender.instance_of?(Contact)

    sender&.available_name || sender&.name
  end
end
