# Builds the model chat for Copilot turns. The including service sets @messages, @tools and @model, and defines
# setup_event_handlers and feature_name.
module Captain::ChatHelper
  include Integrations::LlmInstrumentation
  include Captain::ChatGenerationRecorder

  attr_reader :llm_protocol

  private

  def build_chat
    options = Captain::ResponsesConfig.options(model: @model, temperature: temperature, feature: @llm_feature)
    @llm_protocol = options[:protocol]
    llm_chat = chat(model: @model, **options)
    format = { type: 'json_object' }
    # Responses JSON mode requires "json" in input, excluding system instructions.
    if options[:protocol] == :responses
      format = { type: 'json_schema', name: 'copilot_response', schema: { type: 'object', additionalProperties: true }, strict: false }
    end
    provider_options = Captain::ResponsesConfig.json_format_options(protocol: options[:protocol], format: format)
    llm_chat = llm_chat.with_provider_options(**provider_options)

    llm_chat = setup_system_instructions(llm_chat.with_tools(*Array(@tools)))
    setup_event_handlers(llm_chat)
  end

  def setup_system_instructions(chat)
    system_messages = @messages.select { |m| m[:role] == 'system' || m[:role] == :system }
    combined_instructions = system_messages.pluck(:content).join("\n\n")
    chat.with_instructions(combined_instructions)
  end

  def parse_json_response(content)
    content = content.gsub('```json', '').gsub('```', '')
    content = content.strip
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error parsing JSON response: #{e.message}"
    { 'content' => content }
  end

  def instrumentation_params(chat = nil)
    {
      span_name: "llm.captain.#{feature_name}",
      account_id: resolved_account_id,
      conversation_id: @conversation_id,
      feature_name: feature_name,
      model: @model,
      messages: chat ? chat.messages.map { |m| { role: m.role.to_s, content: m.content.to_s } } : @messages,
      temperature: temperature,
      metadata: {
        assistant_id: @assistant&.id,
        channel_type: resolved_channel_type,
        source: @source
      }.compact
    }
  end

  def temperature
    @assistant&.config&.[]('temperature').presence&.to_f || 0.5
  end

  def resolved_account_id
    @account&.id || @assistant&.account_id
  end

  def resolved_channel_type
    @conversation&.inbox&.channel_type
  end
end
