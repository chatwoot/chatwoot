class AppleMessagesForBusiness::SendListPickerService < AppleMessagesForBusiness::SendMessageService
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
          listPicker: build_list_picker_sections,
          images: build_images_array
        },
        receivedMessage: build_received_message,
        replyMessage: build_reply_message
      }
    }
  end

  def build_list_picker_sections
    sections = content_attributes['sections'] || [default_section]
    sections.map.with_index do |section, index|
      {
        title: section['title'] || "Section #{index + 1}",
        multipleSelection: section['multiple_selection'] || false,
        order: section['order'] || index,
        listPickerItem: build_list_picker_items(section['items'] || [])
      }
    end
  end

  def build_list_picker_items(items)
    items.map.with_index do |item, index|
      {
        identifier: item['identifier'] || SecureRandom.uuid,
        title: item['title'] || "Item #{index + 1}",
        subtitle: item['subtitle'],
        imageIdentifier: item['image_identifier'],
        order: item['order'] || index
      }
    end
  end

  def build_images_array
    images = content_attributes['images'] || []
    images.map do |image|
      {
        identifier: image['identifier'],
        data: image['data'], # Base64 encoded image data
        description: image['description']
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

  def default_section
    {
      'title' => 'Options',
      'multiple_selection' => false,
      'items' => []
    }
  end

  def content_attributes
    @content_attributes ||= message.content_attributes || {}
  end
end