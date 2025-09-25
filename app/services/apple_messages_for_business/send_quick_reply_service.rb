class AppleMessagesForBusiness::SendQuickReplyService < AppleMessagesForBusiness::SendMessageService
  private

  def message_payload
    {
      sourceId: source_id,
      destinationId: destination_id,
      v: 1,
      type: 'interactive',
      interactiveData: {
        bid: channel.imessage_extension_bid,
        data: {
          requestIdentifier: SecureRandom.uuid,
          mspVersion: '1.0',
          quickReply: {
            summaryText: content_attributes['summary_text'] || 'Quick Reply',
            items: build_quick_reply_items
          }
        },
        receivedMessage: build_received_message,
        replyMessage: build_reply_message
      }
    }
  end

  def build_quick_reply_items
    items = content_attributes['items'] || []
    
    # Ensure we have between 2-5 items as per Apple specification
    if items.empty?
      items = default_items
    elsif items.length > 5
      items = items.first(5)
    elsif items.length < 2
      items += default_items.drop(items.length)
    end

    items.map do |item|
      {
        identifier: item['identifier'] || SecureRandom.uuid,
        title: item['title'] || 'Option'
      }
    end
  end

  def build_received_message
    {
      title: content_attributes['received_title'] || 'Please select an option',
      subtitle: content_attributes['received_subtitle'],
      imageIdentifier: content_attributes['received_image_identifier'],
      style: content_attributes['received_style'] || 'small'
    }
  end

  def build_reply_message
    {
      title: content_attributes['reply_title'] || 'Selected: ${item.title}',
      subtitle: content_attributes['reply_subtitle'],
      imageIdentifier: content_attributes['reply_image_identifier'],
      style: content_attributes['reply_style'] || 'icon'
    }
  end

  def default_items
    [
      { 'title' => 'Yes', 'identifier' => 'yes' },
      { 'title' => 'No', 'identifier' => 'no' }
    ]
  end

  def content_attributes
    @content_attributes ||= message.content_attributes || {}
  end
end