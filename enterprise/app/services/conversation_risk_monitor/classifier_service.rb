class ConversationRiskMonitor::ClassifierService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  SEVERITIES = %w[none complaint critical].freeze
  CONTEXT_MESSAGE_LIMIT = 10
  CONTENT_LIMIT = 8_000

  def initialize(conversation:)
    super()
    @conversation = conversation
    @account = conversation.account
  end

  def perform
    content = conversation_content
    return if content.blank?

    response = instrument_llm_call(instrumentation_params(content)) do
      chat(temperature: 0.0)
        .with_provider_options(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(content)
    end
    parse(response.content)
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    nil
  end

  private

  attr_reader :conversation, :account

  def conversation_content
    recent_public_messages.filter_map do |message|
      content = message_content(message)
      next if content.blank?

      role = message.incoming? ? 'Cliente' : 'Atendente'
      "#{role}: #{content.truncate(2_000)}"
    end.join("\n").truncate(CONTENT_LIMIT)
  end

  def recent_public_messages
    conversation.messages.where(private: false, message_type: %i[incoming outgoing])
                .order(created_at: :desc).limit(CONTEXT_MESSAGE_LIMIT).reverse
  end

  def message_content(message)
    return message.content.squish if message.content.present?

    message.attachments.filter_map { |attachment| attachment.meta&.dig('transcribed_text') }.join(' ').squish
  end

  def parse(content)
    data = JSON.parse(sanitize_json_response(content)).with_indifferent_access
    severity = data[:severity].to_s
    confidence = Float(data[:confidence])
    reason = data[:reason].to_s.squish.truncate(500)
    return unless SEVERITIES.include?(severity) && confidence.between?(0, 1) && reason.present?

    { 'severity' => severity, 'confidence' => confidence, 'reason' => reason, 'source' => 'ai' }
  rescue JSON::ParserError, ArgumentError, TypeError
    nil
  end

  def instrumentation_params(content)
    {
      span_name: 'llm.conversation_risk_monitor.classification',
      model: model,
      temperature: 0.0,
      account_id: account.id,
      conversation_id: conversation.display_id,
      feature_name: 'conversation_risk_monitor',
      messages: [{ role: 'system', content: system_prompt }, { role: 'user', content: content }]
    }
  end

  def system_prompt
    <<~PROMPT
      Você monitora conversas de atendimento de uma loja de móveis. Sua única tarefa é detectar riscos; nunca responda ao cliente e nunca sugira ações.

      Classifique como:
      - none: atendimento comum, dúvida ou solicitação operacional sem insatisfação relevante
      - complaint: insatisfação, defeito, atraso, falha, cobrança problemática ou problema sem solução
      - critical: ameaça de cancelamento, cobrança indevida reiterada, Procon, advogado, processo ou falha grave/reincidente sem solução

      Considere todo o contexto e não trate palavras isoladas como reclamação. Não inclua dados pessoais no motivo.
      Retorne somente JSON: {"severity":"none","confidence":0.0,"reason":"Motivo curto"}
    PROMPT
  end
end
