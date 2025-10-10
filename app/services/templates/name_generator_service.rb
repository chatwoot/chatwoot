# frozen_string_literal: true

# Service for auto-generating template names, shortcodes, categories, and descriptions
class Templates::NameGeneratorService
  MAX_SHORTCODE_LENGTH = 20
  MAX_NAME_LENGTH = 100

  def initialize(account_id)
    @account_id = account_id
  end

  # Generate a template name from message type and data
  def generate_name(message_type, message_data)
    base_name = extract_base_name(message_type, message_data)
    base_name = slugify(base_name)
    ensure_unique_name(base_name)
  end

  # Generate a unique shortcode from template name
  def generate_shortcode(template_name, account_id = nil)
    account_id ||= @account_id
    base_shortcode = create_shortcode_from_name(template_name)
    ensure_unique_shortcode(base_shortcode, account_id)
  end

  # Detect category from message type
  def detect_category(message_type)
    category_mapping = {
      'time_picker' => 'scheduling',
      'apple_pay' => 'payment',
      'oauth' => 'authentication',
      'form' => 'support',
      'quick_reply' => 'general',
      'list_picker' => 'sales',
      'imessage_app' => 'integration'
    }

    category_mapping[message_type.to_s] || 'general'
  end

  # Generate description from message type and data
  def generate_description(message_type, message_data)
    case message_type.to_s
    when 'quick_reply'
      generate_quick_reply_description(message_data)
    when 'list_picker'
      generate_list_picker_description(message_data)
    when 'time_picker'
      generate_time_picker_description(message_data)
    when 'form'
      generate_form_description(message_data)
    when 'apple_pay'
      generate_apple_pay_description(message_data)
    else
      "#{message_type.to_s.titleize} template"
    end
  end

  private

  # Extract base name from message data
  def extract_base_name(message_type, message_data)
    case message_type.to_s
    when 'quick_reply'
      extract_quick_reply_name(message_data)
    when 'list_picker'
      extract_list_picker_name(message_data)
    when 'time_picker'
      extract_time_picker_name(message_data)
    when 'form'
      extract_form_name(message_data)
    when 'apple_pay'
      extract_apple_pay_name(message_data)
    else
      message_type.to_s.titleize
    end
  end

  # Extract name from quick_reply data
  def extract_quick_reply_name(message_data)
    # Try to get question text from various possible locations
    question = message_data.dig('receivedMessage', 'title') ||
               message_data.dig('received_message', 'title') ||
               message_data.dig('receivedMessage', 'subtitle') ||
               message_data.dig('received_message', 'subtitle') ||
               'quick_reply'

    truncate_name(question)
  end

  # Extract name from list_picker data
  def extract_list_picker_name(message_data)
    title = message_data.dig('listPicker', 'sections', 0, 'title') ||
            message_data.dig('list_picker', 'sections', 0, 'title') ||
            message_data.dig('receivedMessage', 'title') ||
            message_data.dig('received_message', 'title') ||
            'list_picker'

    truncate_name(title)
  end

  # Extract name from time_picker data
  def extract_time_picker_name(message_data)
    title = message_data.dig('receivedMessage', 'title') ||
            message_data.dig('received_message', 'title') ||
            message_data.dig('replyMessage', 'title') ||
            message_data.dig('reply_message', 'title')

    if title.present?
      truncate_name(title)
    else
      'appointment_scheduler'
    end
  end

  # Extract name from form data
  def extract_form_name(message_data)
    title = message_data.dig('receivedMessage', 'title') ||
            message_data.dig('received_message', 'title') ||
            message_data.dig('form', 'title') ||
            'form'

    truncate_name(title)
  end

  # Extract name from apple_pay data
  def extract_apple_pay_name(message_data)
    # Try to get merchant name or description
    merchant = message_data.dig('payment', 'merchantName') ||
               message_data.dig('payment', 'merchant_name') ||
               message_data.dig('receivedMessage', 'title') ||
               message_data.dig('received_message', 'title')

    if merchant.present?
      "payment_#{truncate_name(merchant)}"
    else
      'payment_request'
    end
  end

  # Truncate name to max length
  def truncate_name(name)
    name.to_s.strip[0...MAX_NAME_LENGTH]
  end

  # Convert name to slug format
  def slugify(name)
    name.to_s
        .downcase
        .strip
        .gsub(/[^\w\s-]/, '') # Remove special characters
        .gsub(/\s+/, '_')     # Replace spaces with underscores
        .gsub(/-+/, '_').squeeze('_')      # Replace multiple underscores with single
        .gsub(/^_|_$/, '')    # Remove leading/trailing underscores
  end

  # Ensure name is unique in the account
  def ensure_unique_name(base_name)
    name = base_name
    counter = 1

    while name_exists?(name)
      name = "#{base_name}_#{counter}"
      counter += 1
    end

    name
  end

  # Check if name exists
  def name_exists?(name)
    MessageTemplate.exists?(account_id: @account_id, name: name)
  end

  # Create shortcode from template name
  def create_shortcode_from_name(template_name)
    # Convert to shortcode format
    shortcode = template_name.to_s
                             .downcase
                             .strip
                             .gsub(/[^\w\s-]/, '')
                             .gsub(/\s+/, '_')
                             .gsub(/-+/, '_').squeeze('_')
                             .gsub(/^_|_$/, '')

    # Truncate to max length
    shortcode[0...MAX_SHORTCODE_LENGTH]
  end

  # Ensure shortcode is unique
  def ensure_unique_shortcode(base_shortcode, account_id)
    shortcode = base_shortcode
    counter = 1

    while shortcode_exists?(shortcode, account_id)
      # Calculate available space for counter
      suffix = "_#{counter}"
      max_base_length = MAX_SHORTCODE_LENGTH - suffix.length
      base = base_shortcode[0...max_base_length]
      shortcode = "#{base}#{suffix}"
      counter += 1
    end

    shortcode
  end

  # Check if shortcode exists in either canned responses or message templates
  def shortcode_exists?(shortcode, account_id)
    CannedResponse.exists?(account_id: account_id, short_code: shortcode) ||
      MessageTemplate.exists?(account_id: account_id, name: shortcode)
  end

  # Generate quick_reply description
  def generate_quick_reply_description(message_data)
    title = message_data.dig('receivedMessage', 'title') ||
            message_data.dig('received_message', 'title')

    replies_count = message_data.dig('quickReply', 'replies')&.count ||
                    message_data.dig('quick_reply', 'replies')&.count ||
                    0

    if title.present?
      "Quick reply: #{truncate_description(title)} (#{replies_count} options)"
    else
      "Quick reply with #{replies_count} options"
    end
  end

  # Generate list_picker description
  def generate_list_picker_description(message_data)
    title = message_data.dig('receivedMessage', 'title') ||
            message_data.dig('received_message', 'title')

    sections = message_data.dig('listPicker', 'sections') ||
               message_data.dig('list_picker', 'sections') ||
               []

    total_items = sections.sum { |s| s['items']&.count || 0 }

    if title.present?
      "List picker: #{truncate_description(title)} (#{sections.count} sections, #{total_items} items)"
    else
      "List picker with #{sections.count} sections and #{total_items} items"
    end
  end

  # Generate time_picker description
  def generate_time_picker_description(message_data)
    title = message_data.dig('receivedMessage', 'title') ||
            message_data.dig('received_message', 'title')

    slots_count = message_data.dig('timePicker', 'timeSlots')&.count ||
                  message_data.dig('time_picker', 'timeSlots')&.count ||
                  message_data.dig('time_picker', 'time_slots')&.count ||
                  0

    if title.present?
      "Time picker: #{truncate_description(title)} (#{slots_count} time slots)"
    else
      "Time picker with #{slots_count} available time slots"
    end
  end

  # Generate form description
  def generate_form_description(message_data)
    title = message_data.dig('receivedMessage', 'title') ||
            message_data.dig('received_message', 'title')

    fields = message_data.dig('form', 'fields') || []

    if title.present?
      "Form: #{truncate_description(title)} (#{fields.count} fields)"
    else
      "Form with #{fields.count} fields"
    end
  end

  # Generate apple_pay description
  def generate_apple_pay_description(message_data)
    merchant = message_data.dig('payment', 'merchantName') ||
               message_data.dig('payment', 'merchant_name')

    amount = message_data.dig('payment', 'total', 'amount')

    if merchant.present?
      "Apple Pay: #{merchant}#{amount.present? ? " - #{amount}" : ''}"
    else
      'Apple Pay payment request'
    end
  end

  # Truncate description to reasonable length
  def truncate_description(text, max_length = 80)
    text = text.to_s.strip
    return text if text.length <= max_length

    "#{text[0...max_length]}..."
  end
end
