class AppleMessagesForBusiness::SendOnAppleMessagesForBusinessService < Base::SendOnChannelService
  private

  def channel_class
    Channel::AppleMessagesForBusiness
  end

  def perform_reply
    Rails.logger.info "🔥 SendOnAppleMessagesForBusinessService - Processing message:"
    Rails.logger.info "🔥 Message ID: #{message.id}"
    Rails.logger.info "🔥 Content Type: #{message.content_type}"
    Rails.logger.info "🔥 Content: #{message.content}"
    Rails.logger.info "🔥 Content Attributes: #{message.content_attributes}"
    
    case message.content_type
    when 'text'
      Rails.logger.info "🔥 Routing to text message service"
      send_text_or_attachment_message
    when 'apple_list_picker'
      Rails.logger.info "🔥 Routing to list picker service"
      send_list_picker_message
    when 'apple_time_picker'
      Rails.logger.info "🔥 Routing to time picker service"
      send_time_picker_message
    when 'apple_quick_reply'
      Rails.logger.info "🔥 Routing to quick reply service"
      send_quick_reply_message
    when 'apple_rich_link'
      Rails.logger.info "🔥 Routing to rich link service"
      send_rich_link_message
    when 'apple_form'
      Rails.logger.info "🔥 Routing to form service"
      send_form_message
    else
      Rails.logger.info "🔥 Unknown content type, routing to text message service (fallback)"
      send_text_or_attachment_message # fallback
    end
  end

  def send_text_or_attachment_message
    service = AppleMessagesForBusiness::SendMessageService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def send_list_picker_message
    service = AppleMessagesForBusiness::SendListPickerService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def send_time_picker_message
    service = AppleMessagesForBusiness::SendTimePickerService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def send_quick_reply_message
    service = AppleMessagesForBusiness::SendQuickReplyService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )
    
    response = service.perform
    update_message_status(response)
  end

  def send_rich_link_message
    service = AppleMessagesForBusiness::SendRichLinkService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )

    response = service.perform
    update_message_status(response)
  end

  def send_form_message
    service = AppleMessagesForBusiness::SendMessageService.new(
      channel: channel,
      destination_id: message.conversation.contact_inbox.source_id,
      message: message
    )

    response = service.perform
    update_message_status(response)
  end

  def update_message_status(response)
    if response[:success]
      message.update!(source_id: response[:message_id])
    else
      # For Apple Messages content types, preserve original content_attributes
      # and store error in additional_attributes instead
      if message.content_type.start_with?('apple_')
        message.update!(
          status: :failed,
          additional_attributes: message.additional_attributes.merge(external_error: response[:error])
        )
      else
        message.update!(
          status: :failed,
          content_attributes: { external_error: response[:error] }
        )
      end
    end
  end
end