class Api::V1::Ai::WhatsappTemplateController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user, raise: false
  before_action :authenticate_ai_request

  # POST /api/v1/ai/whatsapp_template
  # Sends a WhatsApp template message to a conversation
  #
  # Parameters:
  #   - conversation_id: ID of the conversation to send template to (required)
  #   - template_name: Name of the WhatsApp template (required)
  #   - template_namespace: Namespace of the template (optional, will be inferred if not provided)
  #   - template_language: Language code for the template (optional, defaults to 'en')
  #   - template_params: Template parameters in enhanced format (optional)
  #     {
  #       "body": {"1": "value1", "2": "value2"},
  #       "header": {"media_url": "https://...", "media_type": "image"},
  #       "buttons": [{"type": "url", "parameter": "value"}]
  #     }
  #
  # Headers:
  #   - X-Api-Token: ALOOSTUDIO_API_TOKEN for authentication
  def create
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] ========================================'
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] 📱 Template send request received'
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📥 Request params: #{params.inspect}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📥 conversation_id param: #{params[:conversation_id]} (type: #{params[:conversation_id].class})"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📥 template_name param: #{params[:template_name]}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📥 template_language param: #{params[:template_language]}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📥 template_namespace param: #{params[:template_namespace]}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📥 template_params param: #{params[:template_params].inspect}"

    # Try to find conversation by actual ID first, then by display_id
    # This handles cases where AI engine might send either ID format
    conversation_id_param = params[:conversation_id].to_i
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 🔍 Looking for conversation with id=#{conversation_id_param} or display_id=#{conversation_id_param}"

    conversation = Conversation.find_by(id: conversation_id_param)
    found_by = 'id'

    unless conversation
      conversation = Conversation.find_by(display_id: conversation_id_param)
      found_by = 'display_id'
    end

    unless conversation
      Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Conversation not found with id=#{conversation_id_param} or display_id=#{conversation_id_param}"
      Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Full params received: #{params.inspect}"
      return render json: { error: 'Conversation not found' }, status: :not_found
    end

    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] ✅ Found conversation by #{found_by}"
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] ✅ Conversation details:'
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Actual database ID: #{conversation.id}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Display ID: #{conversation.display_id}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Account ID: #{conversation.account_id}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Inbox ID: #{conversation.inbox_id}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Channel Type: #{conversation.inbox.channel_type}"

    # Validate conversation is on WhatsApp channel
    unless conversation.inbox.channel_type == 'Channel::Whatsapp'
      Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Conversation #{conversation.id} is not on WhatsApp channel (type: #{conversation.inbox.channel_type})"
      return render json: { error: 'Conversation is not on WhatsApp channel' }, status: :bad_request
    end

    # Validate template name is provided
    unless params[:template_name].present?
      Rails.logger.error '[AI_WHATSAPP_TEMPLATE] Template name is required'
      return render json: { error: 'Template name is required' }, status: :bad_request
    end

    # Get AI agent (assignee) for the conversation
    ai_agent = conversation.assignee
    unless ai_agent&.is_ai?
      Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Conversation #{conversation.id} is not assigned to an AI agent"
      return render json: { error: 'Conversation must be assigned to an AI agent' }, status: :bad_request
    end

    # Set Current.user to the AI agent for activity tracking
    Current.user = ai_agent

    # Store conversation in instance variable for use in helper methods
    @conversation = conversation

    # Build template parameters structure
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] 🔨 Building template parameters...'
    template_params = build_template_params
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] ✅ Template params built: #{template_params.inspect}"

    # Validate template exists before proceeding
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] 🔍 Validating template exists...'
    unless template_exists?(template_params['name'], template_params['language'])
      Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Template '#{template_params['name']}' (language: #{template_params['language']}) not found or not approved"
      Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Channel: #{conversation.inbox.channel.inspect}"
      return render json: {
        error: 'Template not found',
        details: "Template '#{template_params['name']}' with language '#{template_params['language']}' not found or not approved in channel templates"
      }, status: :not_found
    end
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] ✅ Template validation passed'

    # Create message with template parameters
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] 📝 Creating template message...'
    message = create_template_message(conversation, ai_agent, template_params)
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] ✅ Message created: id=#{message.id}"

    # Send the template message via WhatsApp
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] 📤 Sending template message via WhatsApp...'
    send_template_message(message)
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] ✅ Template message sent successfully'

    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] ========================================'
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] ✅ SUCCESS - Template message #{message.id} created and sent"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Conversation ID (actual): #{conversation.id}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Conversation Display ID: #{conversation.display_id}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - Message ID: #{message.id}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE]    - WhatsApp Message ID: #{message.source_id}"
    Rails.logger.info '[AI_WHATSAPP_TEMPLATE] ========================================'

    render json: {
      success: true,
      message_id: message.id,
      conversation_id: conversation.id, # Actual database ID (use this for API calls)
      conversation_display_id: conversation.display_id, # Display ID (for UI)
      template_name: params[:template_name],
      template_language: template_params['language'],
      template_namespace: template_params['namespace'],
      whatsapp_message_id: message.source_id,
      message: 'WhatsApp template message sent successfully'
    }, status: :ok
  rescue StandardError => e
    Rails.logger.error '[AI_WHATSAPP_TEMPLATE] ========================================'
    Rails.logger.error '[AI_WHATSAPP_TEMPLATE] ERROR - Exception occurred'
    Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Error message: #{e.message}"
    Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Error class: #{e.class}"
    Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Request params: #{params.inspect}"
    Rails.logger.error '[AI_WHATSAPP_TEMPLATE] Backtrace:'
    Rails.logger.error e.backtrace.join("\n")
    Rails.logger.error '[AI_WHATSAPP_TEMPLATE] ========================================'
    render json: { error: 'Internal server error', details: e.message }, status: :internal_server_error
  end

  private

  def authenticate_ai_request
    api_token = request.headers['X-Api-Token']
    expected_token = ENV.fetch('ALOOSTUDIO_API_TOKEN', nil)

    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 🔐 Authenticating AI request with token: #{api_token&.truncate(20)}"

    if expected_token.blank?
      Rails.logger.error '[AI_WHATSAPP_TEMPLATE] ALOOSTUDIO_API_TOKEN not configured'
      render json: { error: 'API token not configured' }, status: :internal_server_error
      return
    end

    return if api_token == expected_token

    Rails.logger.error '[AI_WHATSAPP_TEMPLATE] Invalid API token provided'
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def build_template_params
    template_params = {
      'name' => params[:template_name],
      'language' => params[:template_language] || 'en'
    }

    # Find the template to get namespace and category
    channel = @conversation.inbox.channel
    template = find_template_in_channel(channel, template_params['name'], template_params['language'])

    # Add namespace if provided, otherwise infer from template
    if params[:template_namespace].present?
      template_params['namespace'] = params[:template_namespace]
    elsif template&.dig('namespace').present?
      template_params['namespace'] = template['namespace']
    end

    # Add category from template (required for proper template sending)
    template_params['category'] = template['category'] if template&.dig('category').present?

    # Add processed_params if provided (enhanced format)
    template_params['processed_params'] = normalize_template_params(params[:template_params]) if params[:template_params].present?

    template_params
  end

  def template_exists?(template_name, template_language)
    channel = @conversation.inbox.channel
    return false unless channel.respond_to?(:message_templates)

    find_template_in_channel(channel, template_name, template_language).present?
  end

  def find_template_in_channel(channel, template_name, template_language)
    channel.message_templates.find do |t|
      name_match = t['name'] == template_name || t['name']&.downcase == template_name&.downcase
      lang_match = t['language'] == template_language || t['language']&.downcase == template_language&.downcase
      status_match = t['status']&.downcase == 'approved'

      name_match && lang_match && status_match
    end
  end

  def normalize_template_params(params_hash)
    # Ensure params are in the correct format
    # Accept both string keys and symbol keys
    # Convert ActionController::Parameters to regular hash
    normalized = {}

    # Convert ActionController::Parameters to hash if needed
    hash_to_process = if params_hash.is_a?(ActionController::Parameters)
                        params_hash.to_unsafe_h
                      else
                        params_hash
                      end

    hash_to_process.each do |key, value|
      normalized_key = key.to_s

      # Recursively normalize nested structures
      normalized[normalized_key] = if value.is_a?(ActionController::Parameters)
                                     normalize_template_params(value)
                                   elsif value.is_a?(Hash)
                                     normalize_nested_hash(value)
                                   elsif value.is_a?(Array)
                                     value.map do |item|
                                       if item.is_a?(ActionController::Parameters)
                                         normalize_template_params(item)
                                       elsif item.is_a?(Hash)
                                         normalize_nested_hash(item)
                                       else
                                         item
                                       end
                                     end
                                   else
                                     value
                                   end
    end

    normalized
  end

  def normalize_nested_hash(hash)
    normalized = {}
    hash.each do |key, value|
      normalized_key = key.to_s

      # Handle ActionController::Parameters in nested hashes
      normalized[normalized_key] = if value.is_a?(ActionController::Parameters)
                                     normalize_template_params(value)
                                   elsif value.is_a?(Hash)
                                     normalize_nested_hash(value)
                                   else
                                     value
                                   end
    end
    normalized
  end

  def create_template_message(conversation, ai_agent, template_params)
    # Create message with template parameters
    # MessageBuilder expects template_params as a top-level key, not nested in additional_attributes
    # It will handle merging it into additional_attributes correctly
    rendered_content = render_template_content(template_params)

    message_params = {
      content: rendered_content,
      message_type: :outgoing,
      template_params: template_params # Pass as top-level key so MessageBuilder can process it
    }

    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📝 Creating message with params: #{message_params.inspect}"

    message = Messages::MessageBuilder.new(
      ai_agent,
      conversation,
      message_params
    ).perform

    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📝 Message #{message.id} created with template: #{template_params['name']}"
    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] 📋 Message additional_attributes: #{message.additional_attributes.inspect}"
    message
  end

  def render_template_content(template_params)
    # Get the template from channel to extract body text
    channel = @conversation.inbox.channel
    template = find_template_in_channel(channel, template_params['name'], template_params['language'])
    return '' unless template

    # Find the BODY component
    body_component = template['components']&.find { |c| c['type'] == 'BODY' }
    return '' unless body_component

    body_text = body_component['text'] || ''

    # Replace variables with provided values
    processed_params = template_params['processed_params'] || {}
    body_params = processed_params['body'] || {}

    # Replace {{1}}, {{2}}, etc. with actual values
    body_text.gsub(/\{\{(\d+)\}\}/) do |_match|
      key = ::Regexp.last_match(1)
      body_params[key] || body_params[key.to_s] || "{{#{key}}}"
    end
  end

  def send_template_message(message)
    # Use SendOnWhatsappService to send the template message
    # This service handles template processing and sending via WhatsApp API
    Whatsapp::SendOnWhatsappService.new(message: message).perform

    # Check if message was sent successfully
    if message.reload.status == 'failed'
      error_message = message.external_error || 'Failed to send template message'
      Rails.logger.error "[AI_WHATSAPP_TEMPLATE] Failed to send template: #{error_message}"
      raise StandardError, "Template send failed: #{error_message}"
    end

    Rails.logger.info "[AI_WHATSAPP_TEMPLATE] ✅ Template sent successfully, WhatsApp message ID: #{message.source_id}"
  end
end
