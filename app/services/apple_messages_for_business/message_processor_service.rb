class AppleMessagesForBusiness::MessageProcessorService
  include Rails.application.routes.url_helpers

  def initialize(conversation, message_params, user)
    @conversation = conversation
    @message_params = message_params
    @user = user
    @inbox = conversation.inbox
  end

  def process_and_send
    return send_regular_message unless apple_messages_conversation?
    
    # Check if message contains URLs that should be converted to Rich Links
    message_content = @message_params[:content]
    message_parts = split_message_by_urls(message_content)
    
    # If no URLs found, send as regular message
    return send_regular_message if message_parts.empty?
    
    # If only one part and it's not a URL, send as regular message
    if message_parts.length == 1 && message_parts.first[:type] != 'url'
      return send_regular_message
    end
    
    # Send multiple messages for text + Rich Links
    sent_messages = []
    
    message_parts.each do |part|
      case part[:type]
      when 'text'
        sent_messages << send_text_message(part[:content])
      when 'url'
        rich_link_message = create_rich_link_message(part[:content])
        sent_messages << (rich_link_message || send_text_message(part[:content]))
      end
    end
    
    sent_messages.compact
  end

  private

  def apple_messages_conversation?
    @inbox.channel_type == 'Channel::AppleMessagesForBusiness'
  end

  def split_message_by_urls(text)
    return [{ type: 'text', content: text }] if text.blank?
    
    url_regex = /https?:\/\/[^\s<>"{}|\\^`\[\]]+/i
    parts = []
    last_index = 0
    
    text.scan(url_regex) do |match|
      match_start = text.index(match, last_index)
      
      # Add text before URL if exists
      if match_start > last_index
        before_text = text[last_index...match_start].strip
        parts << { type: 'text', content: before_text } if before_text.present?
      end
      
      # Add URL
      parts << { type: 'url', content: match }
      
      last_index = match_start + match.length
    end
    
    # Add remaining text after last URL if exists
    if last_index < text.length
      after_text = text[last_index..-1].strip
      parts << { type: 'text', content: after_text } if after_text.present?
    end
    
    # If no URLs found, return original text
    parts.empty? ? [{ type: 'text', content: text }] : parts
  end

  def send_text_message(content)
    message_params = @message_params.merge(
      content: content,
      content_type: 'text'
    )
    
    Messages::MessageBuilder.new(@user, @conversation, message_params).perform
  end

  def create_rich_link_message(url)
    # Parse OpenGraph data for the URL
    parser_service = AppleMessagesForBusiness::OpenGraphParserService.new(url)
    result = parser_service.parse
    
    # Create Rich Link message with parsed data (or defaults if parsing failed)
    content_attributes = {
      url: result[:url] || url,
      title: result[:title] || url,
      description: result[:description],
      site_name: result[:site_name]
    }
    
    # Only add image data if we have an image URL
    if result[:image_url].present?
      content_attributes[:image_data] = result[:image_url]
      content_attributes[:image_mime_type] = 'image/png' # Default to PNG for web images
    end
    
    rich_link_params = @message_params.merge(
      content: url,
      content_type: 'apple_rich_link',
      content_attributes: content_attributes
    )
    
    Messages::MessageBuilder.new(@user, @conversation, rich_link_params).perform
  rescue StandardError => e
    Rails.logger.error "Rich Link creation failed for URL #{url}: #{e.message}"
    # Fallback to creating a basic Rich Link with just the URL
    fallback_params = @message_params.merge(
      content: url,
      content_type: 'apple_rich_link',
      content_attributes: {
        url: url,
        title: url,
        description: nil,
        image_data: nil, # Use image_data instead of image_url
        site_name: nil
      }
    )
    Messages::MessageBuilder.new(@user, @conversation, fallback_params).perform
  end

  def send_regular_message
    Messages::MessageBuilder.new(@user, @conversation, @message_params).perform
  end
end