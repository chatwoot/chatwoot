class Captain::Llm::ConversationAutoLabelService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  DEBOUNCE_KEY = 'CRM_AUTO_LABEL::%<conversation_id>d'.freeze

  def initialize(assistant, conversation)
    super()
    @assistant = assistant
    @conversation = conversation
    @account = conversation.account
    @content = "#Conversation\n\n#{@conversation.to_llm_text}"
  end

  def generate_and_apply_labels
    data = generate_labels
    return if data.blank?

    suggested_labels = Array(data['labels']).map { |l| l.downcase.strip }.reject(&:blank?)
    return if suggested_labels.empty?

    ensure_labels_exist(suggested_labels)
    @conversation.add_labels(suggested_labels)
  end

  def self.schedule_debounce(conversation)
    scheduled_at = Time.now.utc.to_i
    key = format(DEBOUNCE_KEY, conversation_id: conversation.id)
    Redis::Alfred.setex(key, scheduled_at, 1.hour.to_i)
    ConversationAutoLabelJob.set(wait: 1.hour).perform_later(conversation, scheduled_at)
  end

  def self.debounce_valid?(conversation, scheduled_at)
    key = format(DEBOUNCE_KEY, conversation_id: conversation.id)
    stored = Redis::Alfred.get(key)
    stored.present? && stored.to_i == scheduled_at
  end

  private

  attr_reader :content

  def ensure_labels_exist(labels)
    existing = @account.labels.where(title: labels).pluck(:title)
    (labels - existing).each do |title|
      @account.labels.create(title: title)
    rescue ActiveRecord::RecordInvalid
      nil
    end
  end

  def generate_labels
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_provider_options(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(@content)
    end
    parse_response(response.content)
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: @account).capture_exception
    nil
  end

  def instrumentation_params
    {
      span_name: 'llm.captain.conversation_auto_label',
      model: @model,
      temperature: @temperature,
      account_id: @account.id,
      conversation_id: @conversation.display_id,
      feature_name: 'conversation_auto_label',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { assistant_id: @assistant.id }
    }
  end

  def system_prompt
    existing_labels = @account.labels.pluck(:title).join(', ')
    <<~SYSTEM_PROMPT
      Voce e um assistente de classificacao de conversas de uma loja de moveis.
      Analise a conversa e sugira labels (etiquetas) relevantes.

      Labels existentes na conta: #{existing_labels}

      Categorias de labels possiveis:
      - Produto de interesse: mesa, rack, cadeira, sofa, sala-de-jantar, cama, guarda-roupa, estante, aparador, escritorio, painel, buffet, banco, banqueta
      - Fonte de anuncio: meta-ad (quando mencionam ter visto anuncio no Facebook/Instagram), google-ad, indicacao
      - Categoria de cliente: residencial, corporativo, arquiteto, designer
      - Urgencia: urgente (quando mencionam prazo apertado)

      Regras:
      - Retorne SOMENTE labels que podem ser claramente inferidos da conversa
      - Prefira usar labels existentes quando aplicavel
      - Labels devem ser lowercase, sem espacos (use hifen), sem acentos
      - Nao invente labels que nao se encaixam nas categorias acima
      - Maximo de 5 labels por conversa
      - Retorne JSON: {"labels": ["label1", "label2"]}
      - Retorne {"labels": []} se nao houver labels claros
    SYSTEM_PROMPT
  end

  def parse_response(response)
    return nil if response.nil?

    JSON.parse(response.strip)
  rescue JSON::ParserError => e
    Rails.logger.error "Error parsing auto-label response: #{e.message}"
    nil
  end
end
