class AppleMessagesForBusiness::IncomingMessageService
  include ::FileTypeHelper

  def initialize(inbox:, params:, headers:)
    @inbox = inbox
    @params = params
    @headers = headers
  end

  def perform
    Rails.logger.info '[AMB IncomingMessage] Starting message processing'
    Rails.logger.info "[AMB IncomingMessage] Params: #{@params.inspect}"
    Rails.logger.info "[AMB IncomingMessage] Headers: #{@headers.inspect}"

    unless valid_message?
      Rails.logger.error '[AMB IncomingMessage] Invalid message - validation failed'
      return
    end

    Rails.logger.info '[AMB IncomingMessage] Message validation passed'

    set_contact
    set_conversation
    create_message
    process_attachments if attachments_present?
    process_interactive_data if interactive_message?

    # Re-broadcast message after attachments are processed to update UI
    if attachments_present? && @message.attachments.any?
      Rails.logger.info '[AMB IncomingMessage] Re-broadcasting message with attachments for UI update'
      @message.reload # Ensure we have the latest attachment data
      # Use the built-in message update event method
      @message.send_update_event
    end

    Rails.logger.info '[AMB IncomingMessage] Message processing completed successfully'
  end

  private

  def valid_message?
    has_id = @params['id'].present?
    has_body = @params['body'].present?
    has_attachments = @params['attachments'].present?
    has_interactive = @params['interactiveData'].present?
    has_idr = @params['interactiveDataRef'].present?

    Rails.logger.info "[AMB IncomingMessage] Validation - ID: #{has_id}, Body: #{has_body}, Attachments: #{has_attachments}, Interactive: #{has_interactive}, IDR: #{has_idr}"

    valid = has_id && (has_body || has_attachments || has_interactive || has_idr)
    Rails.logger.info "[AMB IncomingMessage] Message validation result: #{valid}"

    valid
  end

  def set_contact
    Rails.logger.info "[AMB IncomingMessage] Setting contact with source_id: #{source_id}"

    # If this user was previously blocked, unblock them (Apple MSP spec: user can re-initiate)
    AppleMessagesForBusiness::ConversationReopenService.new(
      inbox: @inbox,
      source_id: source_id
    ).perform

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: @inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    # Update contact with latest capability information
    update_contact_capabilities

    Rails.logger.info "[AMB IncomingMessage] Contact set - ID: #{@contact.id}, Name: #{@contact.name}"
  end

  def set_conversation
    # Get the most recent conversation (resolved or open)
    @conversation = @contact_inbox.conversations.order(updated_at: :desc).first

    if @conversation
      Rails.logger.info "[AMB IncomingMessage] Found existing conversation ID: #{@conversation.id}, Status: #{@conversation.status}"

      # If conversation was resolved due to AMB close event, reopen it for this new message
      # This properly handles the case where user sends a message after opting out and then back in
      if @conversation.status == 'resolved' && conversation_closed_by_amb?(@conversation)
        Rails.logger.info "[AMB IncomingMessage] Reopening AMB-closed conversation ID: #{@conversation.id}"
        @conversation.update!(status: 'open', resolved_at: nil)

        # Add a system message about conversation reopening
        @conversation.messages.create!(
          content: 'Customer resumed conversation by sending a new message.',
          account_id: @inbox.account_id,
          inbox_id: @inbox.id,
          message_type: :activity,
          sender: nil,
          content_type: 'text',
          content_attributes: {
            automation_rule_id: nil,
            system_generated: true,
            reopened_by: 'customer_message'
          }
        )
      end

      # Update existing conversation with latest capability information
      update_conversation_capabilities
      return
    end

    Rails.logger.info '[AMB IncomingMessage] Creating new conversation'
    @conversation = ::Conversation.create!(conversation_params)

    # Store Apple Messages routing parameters for automation rules
    store_apple_routing_data

    Rails.logger.info "[AMB IncomingMessage] Created conversation ID: #{@conversation.id}"
  end

  def create_message
    Rails.logger.info "[AMB IncomingMessage] Creating message with content: #{message_content}"
    Rails.logger.info "[AMB IncomingMessage] Message type: #{message_type}"

    @message = @conversation.messages.build(
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: message_sender,
      content_attributes: content_attributes,
      source_id: @params['id']
    )

    @message.save!
    Rails.logger.info "[AMB IncomingMessage] Message created successfully - ID: #{@message.id}"
  end

  def source_id
    @headers[:source_id] || @params['sourceId']
  end

  def message_content
    case @params['type']
    when 'text'
      @params['body']
    when 'interactive'
      extract_interactive_content
    else
      ''
    end
  end

  def message_type
    case @params['type']
    when 'text', 'interactive'
      :incoming
    else
      :activity
    end
  end

  def message_sender
    @contact
  end

  def content_attributes
    attributes = {}

    attributes.merge!(extract_interactive_attributes) if interactive_message?

    attributes[:in_reply_to_external_id] = @params['replyToMessageId'] if @params['replyToMessageId'].present?

    attributes
  end

  def contact_attributes
    {
      name: extract_contact_name,
      additional_attributes: {
        apple_messages_source_id: source_id,
        apple_messages_capabilities: @headers[:capability_list]
      }
    }
  end

  def extract_contact_name
    # Apple Messages doesn't provide contact name in payload
    # Use source_id as fallback
    "Apple User #{source_id[-8..-1]}"
  end

  def conversation_params
    additional_attrs = {
      apple_messages_source_id: source_id,
      apple_messages_capabilities: @headers[:capability_list]
    }

    # Add Apple Messages routing parameters if present
    additional_attrs[:apple_messages_group] = @params['group'] if @params['group'].present?
    additional_attrs[:apple_messages_intent] = @params['intent'] if @params['intent'].present?

    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attrs
    }
  end

  def interactive_message?
    @params['type'] == 'interactive' || @params['interactiveDataRef'].present?
  end

  def attachments_present?
    @params['attachments'].present? && @params['attachments'].is_a?(Array)
  end

  def extract_interactive_content
    # Check if this is an IDR response first
    if @params['interactiveDataRef'].present?
      # For IDR responses, we'll extract content after processing
      # For now, return a placeholder that will be updated after IDR processing
      return 'Processing Interactive Data Reference...'
    end

    interactive_data = @params['interactiveData']
    return '' unless interactive_data

    extract_content_from_interactive_data(interactive_data)
  end

  def extract_content_from_interactive_data(interactive_data)
    # First, try to extract the actual user selection from replyMessage
    if interactive_data['data'] && interactive_data['data']['replyMessage']
      reply_message = interactive_data['data']['replyMessage']

      # Use the title as the main content, with subtitle as additional context
      content_parts = []
      content_parts << reply_message['title'] if reply_message['title'].present?
      content_parts << reply_message['subtitle'] if reply_message['subtitle'].present?

      return content_parts.join(' - ') if content_parts.any?
    end

    # Fallback: Extract meaningful content from interactive data structure
    return 'Interactive Message' unless interactive_data['data']

    data_keys = interactive_data['data'].keys

    # Check for specific interactive response types and extract relevant info
    if data_keys.include?('dynamic') && interactive_data['data']['dynamic']['template'] == 'messageForms'
      # Apple MSP Form response - extract form submissions
      dynamic_data = interactive_data['data']['dynamic']
      return process_form_response(dynamic_data) if dynamic_data['selections']&.any?

      return 'Form Response'
    elsif data_keys.include?('event') && interactive_data['data']['event']['timeslots']
      # Time picker response - extract selected time slot (new format: data.event)
      timeslots = interactive_data['data']['event']['timeslots']
      if timeslots.any?
        selected_time = timeslots.first['startTime']
        return "Selected appointment: #{format_time_slot(selected_time)}"
      end
      return 'Time Picker Response'
    elsif data_keys.include?('timePicker') && interactive_data['data']['timePicker']['event'] && interactive_data['data']['timePicker']['event']['timeslots']
      # Time picker response - extract selected time slot (legacy format: data.timePicker.event)
      timeslots = interactive_data['data']['timePicker']['event']['timeslots']
      if timeslots.any?
        selected_time = timeslots.first['startTime']
        return "Selected appointment: #{format_time_slot(selected_time)}"
      end
      return 'Time Picker Response'
    elsif data_keys.include?('listPicker')
      # List picker response - try to extract selected item from replyMessage or sections
      list_picker = interactive_data['data']['listPicker']
      if list_picker && list_picker['sections']
        # Look for selected items in the "You Selected" section or similar
        selected_section = list_picker['sections'].find { |s| s['title']&.include?('Selected') }
        if selected_section && selected_section['items']&.any?
          selected_item = selected_section['items'].first
          return selected_item['title'] if selected_item['title'].present?
        end
      end
      return 'List Picker Response'
    elsif data_keys.include?('authenticate')
      return 'Authentication Response'
    elsif data_keys.include?('payment')
      return 'Payment Response'
    elsif data_keys.include?('quick-reply')
      # Quick reply response - extract the selected option
      quick_reply = interactive_data['data']['quick-reply']
      if quick_reply && quick_reply['items'] && quick_reply['selectedIndex']
        selected_index = quick_reply['selectedIndex']
        selected_item = quick_reply['items'][selected_index]
        return selected_item['title'] if selected_item && selected_item['title'].present?
      end
      return 'Quick Reply Response'
    else
      return 'Interactive Message Response'
    end
  end

  def extract_interactive_attributes
    interactive_data = @params['interactiveData']
    return {} unless interactive_data

    attributes = {
      interactive_type: determine_interactive_type(interactive_data),
      interactive_data: interactive_data,
      bid: interactive_data['bid']
    }

    # For form responses, extract and store the detailed form data
    if interactive_data['data'] && interactive_data['data']['dynamic'] &&
       interactive_data['data']['dynamic']['template'] == 'messageForms'

      dynamic_data = interactive_data['data']['dynamic']
      attributes[:form_response] = {
        template: dynamic_data['template'],
        version: dynamic_data['version'],
        selections: dynamic_data['selections'] || [],
        submitted_at: Time.current.iso8601
      }
      attributes[:interactive_type] = 'apple_form_response'
    end

    attributes
  end

  def determine_interactive_type_from_data(interactive_data)
    return 'unknown' unless interactive_data['data']

    data_keys = interactive_data['data'].keys

    if data_keys.include?('listPicker')
      'list_picker'
    elsif data_keys.include?('timePicker')
      'time_picker'
    elsif data_keys.include?('event') && interactive_data['data']['event']['timeslots']
      # New format: time picker data directly under event
      'time_picker'
    elsif data_keys.include?('authenticate')
      'authentication'
    elsif data_keys.include?('payment')
      'payment'
    elsif data_keys.include?('quick-reply')
      'quick_reply'
    else
      'custom'
    end
  end

  def determine_interactive_type(interactive_data)
    return 'unknown' unless interactive_data['data']

    data_keys = interactive_data['data'].keys

    # Check for Apple MSP form response first
    if data_keys.include?('dynamic') && interactive_data['data']['dynamic']['template'] == 'messageForms'
      return 'apple_form_response'
    elsif data_keys.include?('listPicker')
      'list_picker'
    elsif data_keys.include?('timePicker')
      'time_picker'
    elsif data_keys.include?('event') && interactive_data['data']['event']['timeslots']
      # New format: time picker data directly under event
      'time_picker'
    elsif data_keys.include?('authenticate')
      'authentication'
    elsif data_keys.include?('payment')
      'payment'
    elsif data_keys.include?('quick-reply')
      'quick_reply'
    else
      'custom'
    end
  end

  def process_attachments
    @params['attachments'].each do |attachment_params|
      process_attachment(attachment_params)
    rescue StandardError => e
      Rails.logger.error "Attachment processing failed for #{attachment_params['name']}: #{e.message}"
      Rails.logger.info 'Skipping attachment and continuing with message processing'
      # Continue processing other attachments or complete the message without this attachment
    end
  end

  def process_attachment(attachment_params)
    Rails.logger.info "[AMB] Processing attachment with params: #{attachment_params.inspect}"
    # Apple Messages attachments can be either direct URLs or encrypted MMCS URLs
    url = attachment_params['url'] || attachment_params['mmcs-url']
    unless url.present?
      Rails.logger.warn '[AMB] Attachment has no URL, skipping.'
      return
    end

    attachment = @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type(attachment_params['mimeType'] || attachment_params['mime-type']) || :file
    )
    Rails.logger.info "[AMB] Created new attachment record: #{attachment.id}, file_type: #{attachment.file_type}"

    if attachment_params['decryption-key'].present?
      Rails.logger.info '[AMB] Attachment is encrypted. Starting encrypted processing.'
      # Encrypted attachment from MMCS
      process_encrypted_attachment(attachment, attachment_params)
    else
      Rails.logger.info '[AMB] Attachment is a direct URL. Starting direct processing.'
      # Direct URL attachment
      process_direct_attachment(attachment, attachment_params, url)
    end
  rescue StandardError => e
    Rails.logger.error "[AMB] Attachment processing failed: #{e.message}"
    Rails.logger.error "[AMB] Backtrace: #{e.backtrace.join("\n")}"
    # Don't re-raise to avoid breaking message processing
  end

  def process_encrypted_attachment(attachment, attachment_params)
    Rails.logger.info '[AMB] Starting encrypted attachment processing.'
    decryption_key = attachment_params['decryption-key'] || attachment_params['key']

    # Step 1: Get temporary download URL using /preDownload endpoint
    download_info = pre_download_attachment(attachment_params)
    return unless download_info

    Rails.logger.info "[AMB] Downloading encrypted attachment from URL: #{download_info[:download_url]}"

    # Step 2: Download encrypted file with proper headers
    begin
      response = HTTParty.get(
        download_info[:download_url],
        headers: download_info[:headers] || {},
        timeout: 30,
        stream_body: true
      )
      raise "Download failed: #{response.code} #{response.message}" unless response.success?

      encrypted_data = response.body
      Rails.logger.info "[AMB] Successfully downloaded #{encrypted_data.bytesize} bytes."
    rescue StandardError => e
      Rails.logger.error "[AMB] Download failed: #{e.class.name}: #{e.message}"
      Rails.logger.error "[AMB] URL: #{download_info[:download_url]}"
      Rails.logger.error "[AMB] Headers: #{download_info[:headers].inspect}"
      raise e
    end

    # Step 3: Decrypt the file
    Rails.logger.info '[AMB] Decrypting file...'
    decrypted_data = AppleMessagesForBusiness::AttachmentCipherService.decrypt(
      encrypted_data,
      decryption_key
    )
    Rails.logger.info "[AMB] Decrypted data size: #{decrypted_data.bytesize} bytes."

    # Step 4: Create a temporary file with decrypted data
    file_name = ["apple_attachment_#{Time.current.to_i}", get_file_extension(attachment_params)]
    temp_file = Tempfile.new(file_name, binmode: true)
    temp_file.write(decrypted_data)
    temp_file.rewind
    Rails.logger.info "[AMB] Temp file created at: #{temp_file.path}"

    # Attach file to the record
    Rails.logger.info '[AMB] Attaching decrypted file to ActiveStorage...'
    attachment.file.attach(
      io: temp_file,
      filename: attachment_params['name'] || "apple_attachment_#{Time.current.to_i}#{get_file_extension(attachment_params)}",
      content_type: attachment_params['mimeType'] || attachment_params['mime-type']
    )

    # Ensure the attachment is saved
    attachment.save!
    attachment.file.blob.update!(analyzed: true)
    Rails.logger.info "[AMB] Attachment saved successfully. ID: #{attachment.id}, File attached: #{attachment.file.attached?}"

  ensure
    if temp_file
      temp_file.close
      temp_file.unlink
      Rails.logger.info '[AMB] Temp file closed and unlinked.'
    end
  end

  def pre_download_attachment(attachment_params)
    Rails.logger.info '[AMB] Preparing to pre-download attachment.'
    # Use Apple MSP /preDownload endpoint to get the actual download URL

    hex_signature = attachment_params['mmcs-signature-hex'] || attachment_params['signature']
    unless hex_signature
      Rails.logger.error '[AMB] Pre-download failed: Missing signature.'
      return nil
    end

    # Convert hex signature to base64 as required by Apple MSP
    base64_signature = Base64.strict_encode64([hex_signature].pack('H*'))

    # Prepare headers for /preDownload request
    headers = {
      'Authorization' => "Bearer #{@inbox.channel.generate_jwt_token}",
      'source-id' => @inbox.channel.business_id,
      'owner' => attachment_params['mmcs-owner'] || attachment_params['owner'],
      'signature' => base64_signature,
      'url' => attachment_params['mmcs-url'] || attachment_params['url']
    }
    Rails.logger.info "[AMB] Pre-download request headers: #{headers.except('Authorization').inspect}"

    # Make request to Apple's /preDownload endpoint
    Rails.logger.info "[AMB] Sending /preDownload request to Apple MSP for attachment: #{attachment_params['name']}"
    response = HTTParty.get(
      "#{AppleMessagesForBusiness::SendMessageService::AMB_SERVER}/preDownload",
      headers: headers,
      timeout: 30
    )

    if response.success?
      download_data = JSON.parse(response.body)
      Rails.logger.info "[AMB] Pre-download successful. Response: #{download_data.inspect}"

      {
        download_url: download_data['download-url'],
        headers: {} # No additional headers needed for the actual download
      }
    else
      Rails.logger.error "[AMB] Pre-download failed with status: #{response.code} #{response.message}"
      Rails.logger.error "[AMB] Pre-download response body: #{response.body}"
      raise "PreDownload failed: #{response.code} #{response.message}"
    end
  end

  def process_direct_attachment(attachment, attachment_params, url)
    Rails.logger.info "Downloading direct attachment from: #{url}"

    attachment_file = Down.download(url, max_size: 15.megabytes)

    attachment.file.attach(
      io: attachment_file,
      filename: attachment_params['name'] || "apple_attachment_#{Time.current.to_i}",
      content_type: attachment_params['mimeType'] || attachment_params['mime-type']
    )

    # Ensure the attachment is saved
    attachment.save!
    Rails.logger.info "Direct attachment saved successfully: #{attachment.id}, file attached: #{attachment.file.attached?}"
  end

  def get_file_extension(attachment_params)
    mime_type = attachment_params['mimeType'] || attachment_params['mime-type']
    case mime_type
    when 'image/png' then '.png'
    when 'image/jpeg' then '.jpg'
    when 'image/gif' then '.gif'
    when 'video/mp4' then '.mp4'
    when 'audio/mpeg' then '.mp3'
    else ''
    end
  end

  def process_interactive_data
    Rails.logger.info '[AMB IncomingMessage] Processing interactive data'

    # Check if this is an IDR (Interactive Data Reference) response
    if @params['interactiveDataRef'].present?
      Rails.logger.info '[AMB IncomingMessage] Detected Interactive Data Reference, processing IDR'
      process_interactive_data_reference
    elsif @params['interactiveData'].present?
      Rails.logger.info '[AMB IncomingMessage] Processing direct interactive data'
      process_direct_interactive_data
    end
  end

  def process_interactive_data_reference
    idr_data = @params['interactiveDataRef']
    Rails.logger.info "[AMB IncomingMessage] IDR data: #{idr_data.inspect}"

    begin
      # Use the IDR service to download and decrypt the full interactive data
      full_interactive_data = AppleMessagesForBusiness::InteractiveDataReferenceService.process_idr_response(
        idr_data,
        @inbox.channel
      )

      Rails.logger.info '[AMB IncomingMessage] Successfully processed IDR, storing full interactive data'

      # Extract content from the decrypted interactive data
      extracted_content = extract_content_from_interactive_data(full_interactive_data)

      # Store the full interactive data for response handling and update message content
      @message.update!(
        content: (extracted_content.presence || 'Interactive Data Reference Response'),
        content_type: determine_content_type_from_data(full_interactive_data),
        content_attributes: @message.content_attributes.merge(
          interactive_response: full_interactive_data,
          idr_processed: true,
          original_idr: idr_data,
          interactive_type: determine_interactive_type_from_data(full_interactive_data),
          bid: full_interactive_data['bid']
        )
      )

      Rails.logger.info '[AMB IncomingMessage] IDR processing completed successfully'
    rescue StandardError => e
      Rails.logger.error "[AMB IncomingMessage] IDR processing failed: #{e.message}"

      # Fallback: store the IDR reference for manual processing
      @message.update!(
        content: 'Interactive Data Reference (Processing Failed)',
        content_type: 'text',
        content_attributes: @message.content_attributes.merge(
          interactive_response: { error: 'IDR processing failed', details: e.message },
          idr_failed: true,
          original_idr: idr_data
        )
      )
    end
  end

  def process_direct_interactive_data
    # Store interactive data for potential response handling
    @message.update!(
      content_type: determine_content_type,
      content_attributes: @message.content_attributes.merge(
        interactive_response: @params['interactiveData']
      )
    )
  end

  def determine_content_type_from_data(interactive_data)
    return 'text' unless interactive_data&.dig('data')

    data_keys = interactive_data['data'].keys
    first_key = data_keys.first

    case first_key
    when 'listPicker'
      'apple_list_picker'
    when 'timePicker'
      'apple_time_picker'
    when 'event'
      # Check if it's a time picker event response
      if interactive_data['data']['event']['timeslots']
        'apple_time_picker'
      else
        'text'
      end
    when 'authenticate'
      'apple_auth'
    when 'payment'
      'apple_pay'
    else
      'text'
    end
  end

  def determine_content_type
    return 'input_email' if attachments_present?

    interactive_data = @params['interactiveData']
    return 'text' unless interactive_data&.dig('data')

    # Check for Apple MSP form response first
    return 'apple_form_response' if interactive_data['data']['dynamic']&.dig('template') == 'messageForms'

    data_keys = interactive_data['data'].keys
    first_key = data_keys.first

    case first_key
    when 'listPicker'
      'apple_list_picker'
    when 'timePicker'
      'apple_time_picker'
    when 'event'
      # Check if it's a time picker event response
      if interactive_data['data']['event']['timeslots']
        'apple_time_picker'
      else
        'text'
      end
    when 'authenticate'
      'apple_auth'
    when 'payment'
      'apple_pay'
    else
      'text'
    end
  end

  def update_contact_capabilities
    return unless @headers[:capability_list].present?

    current_attributes = @contact.additional_attributes || {}
    updated_attributes = current_attributes.merge(
      'apple_messages_capabilities' => @headers[:capability_list]
    )

    @contact.update!(additional_attributes: updated_attributes)
    Rails.logger.info "[AMB IncomingMessage] Updated contact capabilities: #{@headers[:capability_list]}"
  end

  def update_conversation_capabilities
    return unless @headers[:capability_list].present?

    current_attributes = @conversation.additional_attributes || {}
    updated_attributes = current_attributes.merge(
      'apple_messages_capabilities' => @headers[:capability_list]
    )

    @conversation.update!(additional_attributes: updated_attributes)
    Rails.logger.info "[AMB IncomingMessage] Updated conversation capabilities: #{@headers[:capability_list]}"
  end

  def process_form_response(dynamic_data)
    # Extract form response data from Apple MSP format
    form_title = dynamic_data['data']&.dig('title') || 'Form'
    selections = dynamic_data['selections'] || []

    # Build human-readable response summary
    return "#{form_title} - Submitted (no responses)" if selections.empty?

    response_summary = ["#{form_title} - Response:"]

    selections.each do |selection|
      page_title = selection['title'] || selection['pageIdentifier'] || 'Question'
      items = selection['items'] || []

      if items.any?
        # Multiple items selected (or single item)
        item_titles = items.map { |item| item['title'] || item['value'] }.compact
        response_summary << "#{page_title}: #{item_titles.join(', ')}" if item_titles.any?
      else
        # Handle case where there might be a direct value
        response_summary << "#{page_title}: [Response provided]"
      end
    end

    response_summary.join("\n")
  end

  def format_time_slot(time_string)
    # Parse the ISO 8601 time string
    time = Time.parse(time_string)
    # Format it into a more readable string
    time.strftime('%B %d, %Y at %I:%M %p %Z')
  rescue ArgumentError
    time_string # Return original string if parsing fails
  end

  # Check if a conversation was closed by AMB close event
  def conversation_closed_by_amb?(conversation)
    conversation.additional_attributes&.dig('closed_by') == 'apple_messages_for_business'
  end

  def store_apple_routing_data
    # Log Apple Messages routing parameters for debugging
    if @params['group'].present? || @params['intent'].present?
      Rails.logger.info "[AMB IncomingMessage] Apple Messages routing - Group: #{@params['group']}, Intent: #{@params['intent']}"

      # Store as conversation custom attributes for easier access in automation rules
      custom_attrs = {}
      custom_attrs[:apple_messages_group] = @params['group'] if @params['group'].present?
      custom_attrs[:apple_messages_intent] = @params['intent'] if @params['intent'].present?

      @conversation.update!(custom_attributes: custom_attrs) if custom_attrs.any?
    end
  end
end
