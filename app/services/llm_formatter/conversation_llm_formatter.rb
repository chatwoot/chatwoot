class LlmFormatter::ConversationLlmFormatter < LlmFormatter::DefaultLlmFormatter
  def format(config = {})
    sections = []
    sections << "Conversation ID: ##{@record.display_id}"
    sections << "Channel: #{@record.inbox.channel.name}"
    sections << "Created At: #{@record.created_at}"
    sections.concat(timing_lines) if config[:include_timestamps]
    sections << 'Message History:'
    sections << if @record.messages.any?
                  build_messages(config)
                else
                  'No messages in this conversation'
                end

    sections << "Contact Details: #{@record.contact.to_llm_text}" if config[:include_contact_details]

    attributes = build_attributes
    if attributes.present?
      sections << 'Conversation Attributes:'
      sections << attributes
    end

    sections.join("\n")
  end

  private

  def build_messages(config = {})
    return "No messages in this conversation\n" if @record.messages.empty?

    messages = @record.messages.where.not(message_type: [:activity, :template]).not_forwarded

    if config[:token_limit]
      build_limited_messages(messages, config)
    else
      build_all_messages(messages, config)
    end
  end

  def build_all_messages(messages, config)
    message_text = ''
    messages.order(created_at: :asc).each do |message|
      # Skip private messages unless explicitly included in config
      next if message.private? && !config[:include_private_messages]

      message_text << format_message(message, config)
    end
    message_text
  end

  def build_limited_messages(messages, config)
    selected = []
    character_count = 0

    messages.reorder(created_at: :desc).each do |message|
      # Skip private messages unless explicitly included in config
      next if message.private? && !config[:include_private_messages]

      formatted = format_message(message, config)
      break if character_count + formatted.length > config[:token_limit]

      selected.prepend(formatted)
      character_count += formatted.length
    end

    selected.join
  end

  def format_message(message, config = {})
    sender = sender_label(message)
    sender = "[Private Note] #{sender}" if message.private?
    sender = "[#{format_time(message.created_at)}] #{sender}" if config[:include_timestamps]
    "#{sender}: #{message.content_for_llm}\n"
  end

  def sender_label(message)
    case message.sender_type
    when 'User'
      'Support Agent'
    when 'Contact'
      'User'
    else
      'Bot'
    end
  end

  # Matches the dashboard's "who spoke last" rule (getLastEmailInSelectedChat): public, not forwarded, incoming or outgoing.
  def timing_lines
    latest = @record.messages.where(message_type: [:incoming, :outgoing], private: false).not_forwarded.reorder(created_at: :desc).first
    customer_last = @record.messages.incoming.reorder(created_at: :desc).first

    lines = ["Current Time: #{format_time(Time.current)}"]
    lines << "Latest Message: from #{sender_label(latest)}, #{time_since(latest.created_at)}" if latest
    lines << (customer_last ? "Customer Last Wrote: #{time_since(customer_last.created_at)}" : 'Customer Last Wrote: never')
    lines
  end

  def format_time(time)
    time.utc.strftime('%Y-%m-%d %H:%M UTC')
  end

  def time_since(time)
    minutes = ((Time.current - time) / 60).floor
    return "#{minutes} minutes ago" if minutes < 60

    hours = minutes / 60
    return "#{hours} hours ago" if hours < 48

    "#{hours / 24} days ago"
  end

  def build_attributes
    attributes = @record.account.custom_attribute_definitions.with_attribute_model('conversation_attribute').map do |attribute|
      "#{attribute.attribute_display_name}: #{@record.custom_attributes[attribute.attribute_key]}"
    end
    attributes.join("\n")
  end
end
