require 'google/cloud/dialogflow/v2'
require 'google/protobuf'

class Integrations::Dialogflow::ProcessorService < Integrations::BotProcessorService
  pattr_initialize [:event_name!, :hook!, :event_data!]

  private

  def message_content(message)
    # TODO: might needs to change this to a way that we fetch the updated value from event data instead
    # cause the message.updated event could be that that the message was deleted

    return message.content_attributes['submitted_values']&.first&.dig('value') if event_name == 'message.updated'

    message.content
  end

  def get_response(session_id, message_content)
    if hook.settings['credentials'].blank?
      Rails.logger.warn "Account: #{hook.try(:account_id)} Hook: #{hook.id} credentials are not present." && return
    end

    configure_dialogflow_client_defaults
    detect_intent(session_id, message_content)
  rescue Google::Cloud::PermissionDeniedError => e
    Rails.logger.warn "DialogFlow Error: (account-#{hook.try(:account_id)}, hook-#{hook.id}) #{e.message}"
    hook.prompt_reauthorization!
    hook.disable
  end

  def process_response(message, response)
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === INICIANDO PROCESSAMENTO DA RESPOSTA DO DIALOGFLOW ==="
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"
    
    # Log da resposta integral do Dialogflow ANTES da conversão
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Resposta RAW do Dialogflow (objeto protobuf): #{response.inspect}"
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Query Result RAW: #{response.query_result.inspect}"
    
    # Converter toda a query_result para hash para ver a estrutura completa
    query_result_hash = response.query_result.to_h
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] QUERY RESULT COMPLETO EM HASH: #{query_result_hash.inspect}"
    
    # Log de campos específicos importantes
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] fulfillmentText: #{query_result_hash[:fulfillment_text]}"
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] action: #{query_result_hash[:action]}"
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] parameters: #{query_result_hash[:parameters]}"
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] intent: #{query_result_hash[:intent]}"
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] webhookPayload: #{query_result_hash[:webhook_payload]}"
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] diagnosticInfo: #{query_result_hash[:diagnostic_info]}"
    
    fulfillment_messages = response.query_result['fulfillment_messages']
    
    # Log da resposta APÓS conversão para hash
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Fulfillment Messages (após conversão hash): #{fulfillment_messages.inspect}"
    
    fulfillment_messages.each_with_index do |fulfillment_message, index|
      Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Processando fulfillment_message[#{index}] RAW: #{fulfillment_message.inspect}"
      
      # Converter fulfillment_message completo para hash
      fulfillment_message_hash = fulfillment_message.to_h
      Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] fulfillment_message[#{index}] COMPLETO EM HASH: #{fulfillment_message_hash.inspect}"
      
      content_params = generate_content_params(fulfillment_message)
      
      Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Content params gerados[#{index}]: #{content_params.inspect}"
      
      # Verificar se há payloads especiais como socialwiseResponse
      if content_params['socialwiseResponse'].present?
        Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse detectado: #{content_params['socialwiseResponse'].inspect}"
        
        # Processar socialwiseResponse com Instagram Response Processor
        if process_socialwise_response(content_params['socialwiseResponse'], message)
          Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processado com sucesso, pulando mensagem normal"
          next # Pular criação de mensagem normal quando socialwiseResponse é processado com sucesso
        else
          Rails.logger.warn "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse falhou, continuando com fluxo normal"
          # Continua com fluxo normal se falhar (fallback automático)
        end
      end
      
      if content_params['action'].present?
        Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Ação detectada: #{content_params['action']}"
        process_action(message, content_params['action'])
      else
        Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Criando conversa com content_params: #{content_params.inspect}"
        create_conversation(message, content_params)
      end
    end
    
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === FINALIZANDO PROCESSAMENTO DA RESPOSTA DO DIALOGFLOW ==="
  end

  def generate_content_params(fulfillment_message)
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === GERANDO CONTENT PARAMS ==="
    
    # Processar text response
    text_response = fulfillment_message['text'].to_h
    content_params = { content: text_response[:text].first } if text_response[:text].present?
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Content params do TEXT: #{content_params.inspect}"
    
    # Processar payload
    payload_hash = fulfillment_message['payload'].to_h
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] PAYLOAD HASH COMPLETO: #{payload_hash.inspect}"
    
    # Se não há text, usar o payload
    content_params ||= payload_hash
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] CONTENT PARAMS FINAL: #{content_params.inspect}"
    
    content_params
  end

  # Process socialwiseResponse using Instagram Response Processor
  # @param socialwise_data [Hash] The socialwiseResponse data from Dialogflow
  # @param message [Message] The message object
  # @return [Boolean] true if processing was successful, false otherwise
  def process_socialwise_response(socialwise_data, message)
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === STARTING SOCIALWISE RESPONSE PROCESSING ==="
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] SocialWise data: #{socialwise_data.inspect}"
    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Message ID: #{message.id}, Conversation ID: #{message.conversation.id}"

    # Validate Instagram channel before processing
    conversation = message.conversation
    unless conversation.inbox.channel_type == 'Channel::Instagram'
      Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse only supported for Instagram channels, got: #{conversation.inbox.channel_type}"
      Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Skipping socialwiseResponse processing, will continue with normal flow"
      return false
    end

    Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Instagram channel validated, processing socialwiseResponse"

    # Process with Instagram Response Processor
    begin
      success = Integrations::Socialwise::InstagramResponseProcessor.process(socialwise_data, message)
      
      if success
        Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processed successfully by Instagram Response Processor"
      else
        Rails.logger.warn "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processing failed, will fallback to normal flow"
      end
      
      Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === SOCIALWISE RESPONSE PROCESSING COMPLETED ==="
      success
    rescue => e
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === SOCIALWISE RESPONSE PROCESSING EXCEPTION ==="
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Exception class: #{e.class}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Exception message: #{e.message}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Message ID: #{message.id}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Conversation ID: #{message.conversation.id}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Account ID: #{message.conversation.account_id}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Inbox ID: #{message.conversation.inbox_id}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Channel type: #{message.conversation.inbox.channel_type}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] SocialWise data: #{socialwise_data.inspect}"
      Rails.logger.error "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Backtrace: #{e.backtrace.join('\n')}"
      Rails.logger.info "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Will fallback to normal flow due to exception"
      false
    end
  end

  def create_conversation(message, content_params)
    return if content_params.blank?

    conversation = message.conversation
    conversation.messages.create!(
      content_params.merge(
        {
          message_type: :outgoing,
          account_id: conversation.account_id,
          inbox_id: conversation.inbox_id
        }
      )
    )
  end

  def configure_dialogflow_client_defaults
    ::Google::Cloud::Dialogflow::V2::Sessions::Client.configure do |config|
      config.timeout = 10.0
      config.credentials = hook.settings['credentials']
      config.endpoint = dialogflow_endpoint
    end
  end

  def normalized_region
    region = hook.settings['region'].to_s.strip
    (region.presence || 'global')
  end

  def dialogflow_endpoint
    region = normalized_region
    return 'dialogflow.googleapis.com' if region == 'global'

    "#{region}-dialogflow.googleapis.com"
  end

  ##################################################################
  # UTILITÁRIO – converte Hash simples em google.protobuf.Struct
  ##################################################################
  def hash_to_struct(hash)
    fields = hash.each_with_object({}) do |(k, v), h|
      h[k.to_s] =
        case v
        when TrueClass, FalseClass
          Google::Protobuf::Value.new(bool_value: v)
        when Numeric
          Google::Protobuf::Value.new(number_value: v)
        when Hash
          Google::Protobuf::Value.new(struct_value: hash_to_struct(v))
        else
          Google::Protobuf::Value.new(string_value: v.to_s)
        end
    end

    Google::Protobuf::Struct.new(fields: fields)
  end

  ##################################################################
  # ENVIO A DIALOGFLOW
  ##################################################################
  def detect_intent(session_id, message)
    client  = ::Google::Cloud::Dialogflow::V2::Sessions::Client.new
    session = build_session_path(session_id)

    # ---------- texto que o usuário enviou ------------
    query_input = {
      text: {
        text:          message,
        language_code: 'pt-BR'
      }
    }

    # ---------- monta payload extra se Socialwise ativo ------------
    query_params = nil
    if socialwise_chatwit_enabled?
      extra_payload = build_whatsapp_payload_data
      unless extra_payload.blank?
        Rails.logger.info "[SOCIALWISE] Enviando payload oculto: #{extra_payload.inspect}"
        query_params = { payload: hash_to_struct(extra_payload) }
      end
    end

    # ---------- request final --------------------------
    request = {
      session:     session,
      query_input: query_input
    }
    request[:query_params] = query_params if query_params

    client.detect_intent(request)   # <-- faz a chamada
  end

  def build_session_path(session_id)
    project_id = hook.settings['project_id']
    region = normalized_region

    if region == 'global'
      "projects/#{project_id}/agent/sessions/#{session_id}"
    else
      "projects/#{project_id}/locations/#{region}/agent/sessions/#{session_id}"
    end
  end

  def socialwise_chatwit_enabled?
    # Use shared SocialWise service to check if integration is active
    Integrations::Socialwise::WebhookEnhancerService.socialwise_active?(hook.account)
  end

  def build_whatsapp_payload_data
    # Use shared SocialWise service to get structured data
    message = event_data[:message]
    conversation = message.conversation
    contact = conversation.contact
    inbox = conversation.inbox
    
    # Create a webhook-like payload for the shared service
    webhook_payload = {
      message: message,
      conversation: conversation,
      contact: contact,
      inbox: inbox
    }
    
    # Get enhanced payload from shared service
    enhanced_payload = Integrations::Socialwise::WebhookEnhancerService.enhance_payload(webhook_payload, hook.account)
    socialwise_data = enhanced_payload['socialwise-chatwit']
    
    return {} unless socialwise_data
    
    # Convert nested structure to flat structure for Dialogflow backward compatibility
    flat_payload = {}
    
    # WhatsApp identifiers (removendo duplicação - mantendo apenas wamid)
    if socialwise_data['whatsapp_identifiers']
      flat_payload['wamid'] = socialwise_data['whatsapp_identifiers']['wamid']
      flat_payload['contact_source'] = socialwise_data['whatsapp_identifiers']['contact_source']
    end
    
    # Contact data
    if socialwise_data['contact_data']
      flat_payload['contact_name'] = socialwise_data['contact_data']['name']
      flat_payload['contact_phone'] = socialwise_data['contact_data']['phone_number']
      flat_payload['contact_email'] = socialwise_data['contact_data']['email']
      flat_payload['contact_identifier'] = socialwise_data['contact_data']['identifier']
      flat_payload['contact_id'] = socialwise_data['contact_data']['id']
      
      # Merge custom attributes at root level for backward compatibility
      if socialwise_data['contact_data']['custom_attributes'].is_a?(Hash)
        flat_payload.merge!(socialwise_data['contact_data']['custom_attributes'])
      end
    end
    
    # Conversation data
    if socialwise_data['conversation_data']
      flat_payload['conversation_id'] = socialwise_data['conversation_data']['id']
      flat_payload['conversation_status'] = socialwise_data['conversation_data']['status']
      flat_payload['conversation_assignee_id'] = socialwise_data['conversation_data']['assignee_id']
      flat_payload['conversation_created_at'] = socialwise_data['conversation_data']['created_at']
      flat_payload['conversation_updated_at'] = socialwise_data['conversation_data']['updated_at']
    end
    
    # Message data
    if socialwise_data['message_data']
      flat_payload['message_id'] = socialwise_data['message_data']['id']
      flat_payload['message_content'] = socialwise_data['message_data']['content']
      flat_payload['message_type'] = socialwise_data['message_data']['message_type']
      flat_payload['message_created_at'] = socialwise_data['message_data']['created_at']
      flat_payload['message_content_type'] = socialwise_data['message_data']['content_type']
      
      # Interactive data (button/list IDs)
      if socialwise_data['message_data']['interactive_data']
        interactive_data = socialwise_data['message_data']['interactive_data']
        flat_payload['button_id'] = interactive_data['button_id']
        flat_payload['button_title'] = interactive_data['button_title']
        flat_payload['list_id'] = interactive_data['list_id']
        flat_payload['list_title'] = interactive_data['list_title']
        flat_payload['list_description'] = interactive_data['list_description']
        flat_payload['interaction_type'] = interactive_data['interaction_type']
      end

      # Instagram postback/quick_reply data
      if socialwise_data['message_data']['instagram_data']
        instagram_data = socialwise_data['message_data']['instagram_data']
        flat_payload['postback_payload'] = instagram_data['postback_payload']
        flat_payload['quick_reply_payload'] = instagram_data['quick_reply_payload']
        flat_payload['interaction_type'] = instagram_data['interaction_type']
      end
    end
    
    # Inbox data
    if socialwise_data['inbox_data']
      flat_payload['inbox_id'] = socialwise_data['inbox_data']['id']
      flat_payload['inbox_name'] = socialwise_data['inbox_data']['name']
      flat_payload['channel_type'] = socialwise_data['inbox_data']['channel_type']
    end
    
    # Account data
    if socialwise_data['account_data']
      flat_payload['account_id'] = socialwise_data['account_data']['id']
      flat_payload['account_name'] = socialwise_data['account_data']['name']
    end
    
    # WhatsApp API key, phone number ID, business ID and metadata
    flat_payload['whatsapp_api_key'] = socialwise_data['whatsapp_api_key']
    flat_payload['phone_number_id'] = socialwise_data['whatsapp_phone_number_id']
    flat_payload['business_id'] = socialwise_data['whatsapp_business_id']
    
    if socialwise_data['metadata']
      flat_payload['socialwise_active'] = socialwise_data['metadata']['socialwise_active']
      flat_payload['is_whatsapp_channel'] = socialwise_data['metadata']['is_whatsapp_channel']
      flat_payload['has_whatsapp_api_key'] = socialwise_data['metadata']['has_whatsapp_api_key']
      flat_payload['payload_version'] = socialwise_data['metadata']['payload_version']
      flat_payload['timestamp'] = socialwise_data['metadata']['timestamp']
    end
    
    Rails.logger.info "[SOCIALWISE] Dialogflow payload built using shared service: #{flat_payload.inspect}"
    
    flat_payload
  rescue => e
    Rails.logger.error "[SOCIALWISE] Error building Dialogflow payload: #{e.class}: #{e.message}"
    Rails.logger.error "[SOCIALWISE] Backtrace: #{e.backtrace.join('\n')}"
    
    # Fallback payload with essential data
    message = event_data[:message]
    conversation = message.conversation
    contact = conversation.contact
    
    {
      "wamid" => message.source_id,
      "contact_name" => contact.name,
      **(contact.custom_attributes.to_h rescue {}),
      "socialwise_active" => true,
      "whatsapp_api_key" => nil,
      "phone_number_id" => nil,
      "business_id" => nil,
      "has_whatsapp_api_key" => false,
      "error" => "Payload construction failed: #{e.class}: #{e.message}"
    }
  end
end
