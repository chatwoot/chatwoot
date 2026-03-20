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

  def first_reply_created_at
    format_datetime(@obj.try(:first_reply_created_at))
  end

  def first_reply_created_at_time
    format_datetime(@obj.try(:first_reply_created_at), include_time: true)
  end

  def last_activity_at
    format_datetime(@obj.try(:last_activity_at))
  end

  def last_activity_at_time
    format_datetime(@obj.try(:last_activity_at), include_time: true)
  end

  private

  def format_datetime(datetime, include_time: false)
    return '' if datetime.blank?

    locale = @obj.try(:account)&.locale || 'en'
    date_format = locale == 'pt_BR' ? '%d/%m/%Y' : '%b %d, %Y'
    date_format += ' %H:%M' if include_time
    datetime.strftime(date_format)
  end

  def message_sender_name(sender)
    return 'Bot' if sender.blank?
    return contact_name if sender.instance_of?(Contact)

    sender&.available_name || sender&.name
  end
end
