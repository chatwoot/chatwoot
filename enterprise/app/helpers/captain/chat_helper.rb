module Captain::ChatHelper
  def request_chat_completion
    log_chat_completion_request

    response = @client.chat(
      parameters: {
        model: @model,
        messages: @messages,
        tools: @tool_registry&.registered_tools || [],
        response_format: { type: 'json_object' },
        temperature: @assistant&.config&.[]('temperature').to_f || 1
      }
    )

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error in chat completion: #{e}"
    raise e
  end

  def message_content_multimodal(message)
    # If message has text content, start with that
    content_parts = []

    if message.content.present?
      content_parts << {
        type: 'text',
        text: message.content
      }
    end

    # Add image content if available
    if message.attachments.any?
      image_attachments = message.attachments.where(file_type: :image)

      image_attachments.each do |attachment|
        image_url = get_attachment_url(attachment)
        next unless image_url.present?

        content_parts << {
          type: 'image_url',
          image_url: {
            url: image_url
          }
        }
      end

      # Handle audio transcriptions
      audio_transcriptions = extract_audio_transcriptions(message.attachments)
      if audio_transcriptions.present?
        content_parts << {
          type: 'text',
          text: audio_transcriptions
        }
      end

      # Handle other attachment types
      other_attachments = message.attachments.where.not(file_type: [:image, :audio])
      if other_attachments.any?
        content_parts << {
          type: 'text',
          text: 'User has shared an attachment'
        }
      end
    end

    # Return just text if no special content, otherwise return array for multimodal
    if content_parts.length == 1 && content_parts.first[:type] == 'text'
      content_parts.first[:text]
    elsif content_parts.any?
      content_parts
    else
      'Message without content'
    end
  end

  def get_attachment_url(attachment)
    if attachment.external_url.present?
      attachment.external_url
    elsif attachment.file.attached?
      # For uploaded files, we need to generate a public URL
      # This will work if the file is stored in a public cloud storage
      attachment.file.url if attachment.file.respond_to?(:url)
    end
  end

  def extract_audio_transcriptions(attachments)
    audio_attachments = attachments.where(file_type: :audio)
    return '' if audio_attachments.blank?

    transcriptions = ''
    audio_attachments.each do |attachment|
      result = Messages::AudioTranscriptionService.new(attachment).perform
      transcriptions += result[:transcriptions] if result[:success]
    end
    transcriptions
  end

  private

  def handle_response(response)
    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }
    message = response.dig('choices', 0, 'message')
    if message['tool_calls']
      process_tool_calls(message['tool_calls'])
    else
      message = JSON.parse(message['content'].strip)
      persist_message(message, 'assistant')
      message
    end
  end

  def process_tool_calls(tool_calls)
    append_tool_calls(tool_calls)
    tool_calls.each do |tool_call|
      process_tool_call(tool_call)
    end
    request_chat_completion
  end

  def process_tool_call(tool_call)
    arguments = JSON.parse(tool_call['function']['arguments'])
    function_name = tool_call['function']['name']
    tool_call_id = tool_call['id']

    if @tool_registry.respond_to?(function_name)
      execute_tool(function_name, arguments, tool_call_id)
    else
      process_invalid_tool_call(function_name, tool_call_id)
    end
  end

  def execute_tool(function_name, arguments, tool_call_id)
    persist_message(
      {
        content: I18n.t('captain.copilot.using_tool', function_name: function_name),
        function_name: function_name
      },
      'assistant_thinking'
    )
    result = @tool_registry.send(function_name, arguments)
    persist_message(
      {
        content: I18n.t('captain.copilot.completed_tool_call', function_name: function_name),
        function_name: function_name
      },
      'assistant_thinking'
    )
    append_tool_response(result, tool_call_id)
  end

  def append_tool_calls(tool_calls)
    @messages << {
      role: 'assistant',
      tool_calls: tool_calls
    }
  end

  def process_invalid_tool_call(function_name, tool_call_id)
    persist_message({ content: I18n.t('captain.copilot.invalid_tool_call'), function_name: function_name }, 'assistant_thinking')
    append_tool_response(I18n.t('captain.copilot.tool_not_available'), tool_call_id)
  end

  def append_tool_response(content, tool_call_id)
    @messages << {
      role: 'tool',
      tool_call_id: tool_call_id,
      content: content
    }
  end

  def log_chat_completion_request
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Requesting chat completion
      for messages #{@messages} with #{@tool_registry&.registered_tools&.length || 0} tools
      "
    )
  end
end
