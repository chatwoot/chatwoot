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

    # CRITICAL: Process IDR immediately if present, before any database operations
    # IDR URLs expire within seconds, so we must download the data first
    Rails.logger.info "[AMB IncomingMessage] Checking for IDR: #{@params.keys.inspect}"
    if @params['interactiveDataRef'].present?
      Rails.logger.info '[AMB IncomingMessage] IDR detected - downloading data immediately before any DB operations'
      @idr_data = download_idr_data
    else
      Rails.logger.info '[AMB IncomingMessage] No IDR in params'
    end

    set_contact
    set_conversation
    create_message
    # CRITICAL: Process interactive data (including IDR) BEFORE attachments
    # If attachment and IDR share the same URL, attachment will consume it
    process_interactive_data if interactive_message?
    process_attachments if attachments_present?

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

    # Determine content type early - this is critical for IDR to prevent UI flicker
    determined_content_type = determine_content_type
    Rails.logger.info "[AMB IncomingMessage] Content type determined: #{determined_content_type} (IDR cached: #{@idr_data.present?})"

    @message = @conversation.messages.build(
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: message_type,
      sender: message_sender,
      content_attributes: content_attributes,
      source_id: @params['id'],
      content_type: determined_content_type
    )

    @message.save!
    Rails.logger.info "[AMB IncomingMessage] Message created successfully - ID: #{@message.id}, content_type: #{@message.content_type}"
  end

  def source_id
    @headers[:source_id] || @params['sourceId']
  end

  def message_content
    case @params['type']
    when 'text'
      parse_tapback_content(@params['body'])
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

    # Add tapback reaction metadata if detected
    attributes.merge!(extract_tapback_attributes(@params['body'])) if @params['type'] == 'text' && is_tapback?(@params['body'])

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

  def extract_from_nskeyed_archiver(interactive_data)
    Rails.logger.info '[AMB IncomingMessage] Parsing NSKeyedArchiver data'

    # Find the URL object in the $objects array
    objects = interactive_data['$objects'] || []
    url_string = nil

    objects.each do |obj|
      if obj.is_a?(String) && obj.start_with?('?')
        url_string = obj
        break
      end
    end

    unless url_string
      Rails.logger.warn '[AMB IncomingMessage] No URL found in NSKeyedArchiver data'
      return 'Interactive Message'
    end

    Rails.logger.info "[AMB IncomingMessage] Found URL: #{url_string}"

    # Parse the URL parameters
    require 'uri'
    require 'cgi'
    require 'base64'
    require 'json'

    params = CGI.parse(url_string.sub(/^\?/, ''))

    # Decode replyMessage from Base64
    if params['replyMessage']&.first
      begin
        decoded = Base64.decode64(params['replyMessage'].first)
        reply_data = JSON.parse(decoded)

        Rails.logger.info "[AMB IncomingMessage] Decoded replyMessage: #{reply_data.inspect}"

        # Extract title and subtitle
        content_parts = []
        content_parts << reply_data['title'] if reply_data['title'].present?
        content_parts << reply_data['subtitle'] if reply_data['subtitle'].present?

        return content_parts.join(' - ') if content_parts.any?
      rescue StandardError => e
        Rails.logger.error "[AMB IncomingMessage] Failed to decode replyMessage: #{e.message}"
      end
    end

    'Interactive Message'
  end

  def extract_content_from_interactive_data(interactive_data)
    Rails.logger.info "[AMB IncomingMessage] Extracting content from interactive data, keys: #{interactive_data&.keys&.inspect}"

    # Handle NSKeyedArchiver format (from list picker responses)
    if interactive_data['$objects'] && interactive_data['$objects'].is_a?(Array)
      Rails.logger.info '[AMB IncomingMessage] Detected NSKeyedArchiver format'
      return extract_from_nskeyed_archiver(interactive_data)
    end

    # First, try to extract the actual user selection from replyMessage
    if interactive_data['data'] && interactive_data['data']['replyMessage']
      reply_message = interactive_data['data']['replyMessage']
      Rails.logger.info "[AMB IncomingMessage] Found replyMessage: #{reply_message.inspect}"

      # Use the title as the main content, with subtitle as additional context
      content_parts = []
      content_parts << reply_message['title'] if reply_message['title'].present?
      content_parts << reply_message['subtitle'] if reply_message['subtitle'].present?

      if content_parts.any?
        extracted = content_parts.join(' - ')
        Rails.logger.info "[AMB IncomingMessage] Extracted content from replyMessage: #{extracted}"
        return extracted
      end
    end

    # Fallback: Extract meaningful content from interactive data structure
    return 'Interactive Message' unless interactive_data['data']

    data_keys = interactive_data['data'].keys
    Rails.logger.info "[AMB IncomingMessage] No replyMessage found, checking data keys: #{data_keys.inspect}"

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
      # List picker response - try to extract selected item(s) from replyMessage or sections
      list_picker = interactive_data['data']['listPicker']
      if list_picker && list_picker['sections']
        # Look for selected items in the "You Selected" section or similar
        selected_section = list_picker['sections'].find { |s| s['title']&.include?('Selected') }
        if selected_section && selected_section['items']&.any?
          # Handle multiple selections
          selected_titles = selected_section['items'].map { |item| item['title'] }.compact
          return selected_titles.join(', ') if selected_titles.any?
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

    # Apple Messages for Business supports attachments up to 100MB
    # Reference: Apple MSP REST API v4.1.5 - type-text.md
    attachment_file = Down.download(url, max_size: 100.megabytes)

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
      # Use cached IDR data if available (downloaded early), otherwise download now
      full_interactive_data = @idr_data || AppleMessagesForBusiness::InteractiveDataReferenceService.process_idr_response(
        idr_data,
        @inbox.channel
      )

      if @idr_data
        Rails.logger.info '[AMB IncomingMessage] Using cached IDR data from early download'
      else
        Rails.logger.warn '[AMB IncomingMessage] No cached IDR data - downloading now (may fail if URL expired)'
      end

      Rails.logger.info '[AMB IncomingMessage] Successfully processed IDR, storing full interactive data'

      # Extract content from the decrypted interactive data
      extracted_content = extract_content_from_interactive_data(full_interactive_data)
      Rails.logger.info "[AMB IncomingMessage] Extracted content: '#{extracted_content}'"

      # Store the full interactive data for response handling and update message content
      # IMPORTANT: Don't change content_type - it causes UI component to re-mount and flicker
      Rails.logger.info "[AMB IncomingMessage] Updating message with IDR data (keeping content_type: #{@message.content_type})"
      Rails.logger.info "[AMB IncomingMessage] Message ID: #{@message.id}, current content: '#{@message.content}'"

      @message.update!(
        content: (extracted_content.presence || 'Interactive Data Reference Response'),
        content_attributes: @message.content_attributes.merge(
          interactive_response: full_interactive_data,
          idr_processed: true,
          original_idr: idr_data,
          interactive_type: determine_interactive_type_from_data(full_interactive_data),
          bid: full_interactive_data['bid']
        )
      )

      @message.reload
      Rails.logger.info '[AMB IncomingMessage] IDR processing completed successfully - content_type unchanged'
      Rails.logger.info "[AMB IncomingMessage] Final message content: '#{@message.content}'"
    rescue StandardError => e
      Rails.logger.error "[AMB IncomingMessage] IDR processing failed: #{e.message}"

      # Try to create a meaningful fallback based on the IDR BID and available data
      fallback_content, fallback_type, fallback_attributes = create_idr_fallback(idr_data, e)

      # Store the fallback with error details for debugging
      @message.update!(
        content: fallback_content,
        content_type: fallback_type,
        content_attributes: @message.content_attributes.merge(fallback_attributes)
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

    # For IDR responses, we need to peek at the cached data to determine type
    # This prevents UI flicker from content_type changing after IDR download
    return determine_content_type_from_data(@idr_data) if @params['interactiveDataRef'].present? && @idr_data.present?

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
    return unless @params['group'].present? || @params['intent'].present?

    Rails.logger.info "[AMB IncomingMessage] Apple Messages routing - Group: #{@params['group']}, Intent: #{@params['intent']}"

    # Store as conversation custom attributes for easier access in automation rules
    custom_attrs = {}
    custom_attrs[:apple_messages_group] = @params['group'] if @params['group'].present?
    custom_attrs[:apple_messages_intent] = @params['intent'] if @params['intent'].present?

    @conversation.update!(custom_attributes: custom_attrs) if custom_attrs.any?
  end

  # Tapback detection and parsing methods
  def is_tapback?(body)
    return false unless body.is_a?(String)

    # Standard tapback patterns (English and localized)
    # Examples: Liked "text", Loved "text", Laughed at "text", etc.
    return true if body.match?(/^(Liked|Loved|Disliked|Laughed at|Emphasized|Questioned)\s+["]/)

    # Emoji reaction pattern: Reacted ☺️ to "text"
    return true if body.match?(/^Reacted\s+.+\s+to\s+["]/)

    # Sticker/Memoji pattern: Reacted with a sticker to "text"
    return true if body.match?(/^Reacted with a sticker to\s+["]/)

    # Interactive message tapback: Liked 1 Business Message
    return true if body.match?(/^(Liked|Loved|Disliked|Laughed at|Emphasized|Questioned)\s+\d+\s+Business Message/)

    # Image tapback: Liked an image
    return true if body.match?(/^(Liked|Loved|Disliked|Laughed at|Emphasized|Questioned)\s+an?\s+(image|video|audio|file)/)

    # Localized patterns (check for unicode quotes and common reaction verbs in other languages)
    # Japanese example: "text"に「いいね」と応答
    return true if body.match?(/["].*["].*[応答|反]/)

    false
  end

  def create_idr_fallback(idr_data, error)
    Rails.logger.info "[AMB IncomingMessage] Creating IDR fallback for BID: #{idr_data['bid']}"

    # Apple uses the same BID for multiple interactive types (list picker, form, etc.)
    # We cannot reliably determine the type without the actual IDR data
    # Use a generic message that works for all interactive responses
    error_message = if error.message.include?('404')
                      'Customer responded to an interactive message'
                    elsif error.message.include?('expired')
                      'Customer responded to an interactive message (data expired)'
                    else
                      'Customer responded to an interactive message'
                    end

    fallback_attributes = {
      interactive_response: {
        error: 'IDR processing failed',
        details: error.message,
        user_message: error_message
      },
      idr_failed: true,
      original_idr: idr_data,
      interactive_type: 'unknown'
    }

    [error_message, 'text', fallback_attributes]
  end

  def parse_tapback_content(body)
    return body unless is_tapback?(body)

    # Return the body as-is for display, but mark it as a tapback reaction
    # The frontend will handle special display
    body
  end

  def extract_tapback_attributes(body)
    attributes = {
      is_tapback_reaction: true
    }

    # Extract reaction type
    case body
    when /^Liked\s+/
      attributes[:tapback_type] = 'like'
      attributes[:tapback_emoji] = '👍'
    when /^Loved\s+/
      attributes[:tapback_type] = 'love'
      attributes[:tapback_emoji] = '❤️'
    when /^Disliked\s+/
      attributes[:tapback_type] = 'dislike'
      attributes[:tapback_emoji] = '👎'
    when /^Laughed at\s+/
      attributes[:tapback_type] = 'laugh'
      attributes[:tapback_emoji] = '😂'
    when /^Emphasized\s+/
      attributes[:tapback_type] = 'emphasize'
      attributes[:tapback_emoji] = '!!'
    when /^Questioned\s+/
      attributes[:tapback_type] = 'question'
      attributes[:tapback_emoji] = '??'
    when /^Reacted\s+(.+?)\s+to\s+/
      # Extract emoji from "Reacted ☺️ to" pattern
      emoji_match = body.match(/^Reacted\s+(.+?)\s+to\s+/)
      attributes[:tapback_type] = 'emoji'
      attributes[:tapback_emoji] = emoji_match[1] if emoji_match
    when /^Reacted with a sticker/
      attributes[:tapback_type] = 'sticker'
      attributes[:tapback_emoji] = '🎨'
    end

    # Extract referenced message text if present (between quotes)
    if (match = body.match(/["](.+?)["]$/))
      attributes[:tapback_referenced_text] = match[1]
    elsif body.match?(/Business Message/)
      attributes[:tapback_referenced_text] = 'Business Message'
    elsif (match = body.match(/an?\s+(image|video|audio|file)$/))
      attributes[:tapback_referenced_text] = match[1]
    end

    attributes
  end

  # Download IDR data immediately when webhook is received
  # IDR URLs expire very quickly (seconds), so we must download before any other processing
  def download_idr_data
    idr_params = @params['interactiveDataRef']
    Rails.logger.info "[AMB IncomingMessage] Downloading IDR immediately: #{idr_params['url']}"

    # Check if any attachment shares the same URL
    # Apple sometimes uses the same URL for both attachment and IDR with different signatures
    if @params['attachments'].present?
      attachment_with_same_url = @params['attachments'].find { |att| att['url'] == idr_params['url'] || att['mmcs-url'] == idr_params['url'] }

      if attachment_with_same_url
        Rails.logger.warn '[AMB IncomingMessage] IDR shares URL with attachment - Apple may reject duplicate /preDownload'
        Rails.logger.warn "[AMB IncomingMessage] Attachment signature: #{attachment_with_same_url['signature']}"
        Rails.logger.warn "[AMB IncomingMessage] IDR signature: #{idr_params['signature']}"
        # Continue with download attempt - Apple might allow different signatures
      end
    end

    begin
      # Download and decrypt the IDR data using the service
      full_data = AppleMessagesForBusiness::InteractiveDataReferenceService.process_idr_response(
        idr_params,
        @inbox.channel
      )

      Rails.logger.info '[AMB IncomingMessage] IDR download successful (early processing)'
      full_data
    rescue StandardError => e
      Rails.logger.error "[AMB IncomingMessage] Failed to download IDR early: #{e.message}"
      nil
    end
  end
end
