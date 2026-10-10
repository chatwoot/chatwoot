# The detailed evaluation prompt intentionally lives with its parser contract.
# rubocop:disable Metrics/ClassLength
class ConversationInsight::QualitativeAnalysisService < Llm::BaseAiService
  include Integrations::LlmInstrumentation

  VALID_CLASSIFICATIONS = %w[complete_consultation quick_consultation return_client non_commercial].freeze
  VALID_SENTIMENTS = %w[positive neutral negative].freeze
  VALID_FUNNEL_STAGES = %w[Lead Qualificado Orcamento Negociacao Venda Perda].freeze

  CRITERIA_KEYS = %w[
    needs_qualification closing_conduct media_usage personalization
    unfulfilled_promises alternatives_offered tone_communication
    return_client_continuity cross_sell
  ].freeze

  def initialize(assistant, conversation)
    super()
    @assistant = assistant
    @conversation = conversation
    @content = "#Conversation\n\n#{@conversation.to_llm_text}"
  end

  def analyze
    response = instrument_llm_call(instrumentation_params) do
      chat
        .with_provider_options(response_format: { type: 'json_object' })
        .with_instructions(system_prompt)
        .ask(@content)
    end

    parse_and_validate(response.content)
  rescue RubyLLM::Error => e
    ChatwootExceptionTracker.new(e, account: @conversation.account).capture_exception
    nil
  end

  private

  attr_reader :content

  def instrumentation_params
    {
      span_name: 'llm.conversation_insight.qualitative_analysis',
      model: @model,
      temperature: @temperature,
      account_id: @conversation.account_id,
      conversation_id: @conversation.display_id,
      feature_name: 'conversation_insight_qualitative',
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: @content }
      ],
      metadata: { assistant_id: @assistant.id }
    }
  end

  def parse_and_validate(response)
    return nil if response.nil?

    data = JSON.parse(response.strip)
    normalize(data)
  rescue JSON::ParserError => e
    Rails.logger.error "QualitativeAnalysisService parse error: #{e.message}"
    nil
  end

  def normalize(data)
    {
      'conversation_classification' => normalize_classification(data['conversation_classification']),
      'classification_justification' => data['classification_justification'].to_s.truncate(500),
      'estimated_value' => data['estimated_value'].to_f,
      'product_category' => data['product_category'].to_s.truncate(100),
      'customer_sentiment' => normalize_sentiment(data['customer_sentiment']),
      'key_topics' => Array(data['key_topics']).first(10),
      'suggested_funnel_stage' => normalize_funnel_stage(data['suggested_funnel_stage']),
      'criteria' => normalize_criteria(data['criteria']),
      'feedback_summary' => data['feedback_summary'].to_s.truncate(1000)
    }
  end

  def normalize_classification(value)
    VALID_CLASSIFICATIONS.include?(value) ? value : 'complete_consultation'
  end

  def normalize_sentiment(value)
    VALID_SENTIMENTS.include?(value) ? value : 'neutral'
  end

  def normalize_funnel_stage(value)
    VALID_FUNNEL_STAGES.include?(value) ? value : nil
  end

  def normalize_criteria(criteria)
    return {} unless criteria.is_a?(Hash)

    normalized = {}
    CRITERIA_KEYS.each do |key|
      criterion = criteria[key]
      next unless criterion.is_a?(Hash)

      normalized[key] = normalize_single_criterion(key, criterion)
    rescue StandardError => e
      Rails.logger.warn "QualitativeAnalysis: failed to parse criterion #{key}: #{e.message}"
      normalized[key] = nil
    end
    normalized
  end

  def normalize_single_criterion(key, criterion)
    if key == 'unfulfilled_promises'
      {
        'flagged' => criterion['flagged'] == true,
        'justification' => criterion['justification'].to_s.truncate(500)
      }
    else
      score = criterion['score']
      {
        'score' => score&.to_i,
        'justification' => criterion['justification'].to_s.truncate(500)
      }
    end
  end

  def system_prompt
    <<~SYSTEM_PROMPT
      Voce e um analista de vendas especializado em avaliar a qualidade do atendimento comercial via WhatsApp para uma loja de moveis.

      Analise a conversa fornecida e retorne SOMENTE um JSON valido com a seguinte estrutura:

      {
        "conversation_classification": "complete_consultation|quick_consultation|return_client|non_commercial",
        "classification_justification": "1 frase explicando a classificacao",
        "estimated_value": 0.00,
        "product_category": "string",
        "customer_sentiment": "positive|neutral|negative",
        "key_topics": ["topic1", "topic2"],
        "suggested_funnel_stage": "Lead|Qualificado|Orcamento|Negociacao|Venda|Perda",
        "criteria": {
          "needs_qualification": { "score": 0-5, "justification": "citacao ou explicacao..." },
          "closing_conduct": { "score": 0-5, "justification": "..." },
          "media_usage": { "score": 0-3, "justification": "..." },
          "personalization": { "score": 0-3, "justification": "..." },
          "unfulfilled_promises": { "flagged": true/false, "justification": "..." },
          "alternatives_offered": { "score": 0-3, "justification": "..." },
          "tone_communication": { "score": 0-3, "justification": "..." },
          "return_client_continuity": { "score": 0-3 ou null, "justification": "..." },
          "cross_sell": { "score": 0-2, "justification": "..." }
        },
        "feedback_summary": "1 ponto positivo + 1-2 pontos de melhoria especificos"
      }

      ## Classificacao da conversa

      - complete_consultation: Cliente demonstrou interesse real, troca de mensagens substancial (4+ turnos de cada lado). Todos os criterios se aplicam.
      - quick_consultation: Pergunta pontual (preco, disponibilidade). Menos de 4 turnos por lado. Criterios de qualificacao e cross-sell tem peso reduzido.
      - return_client: Cliente ja conversou antes (historico visivel). Criterio de continuidade se torna obrigatorio.
      - non_commercial: Pos-venda, reclamacao, spam, engano. Avaliacao simplificada (so tempo + cordialidade).

      ## Criterios de avaliacao

      ### needs_qualification (0-5): Qualificacao da Necessidade
      - 0: Enviou produto/preco sem perguntar nada
      - 1: Uma pergunta generica sem aprofundamento
      - 2: 1-2 perguntas relevantes, pulou para produto cedo
      - 3: 2-3 perguntas relevantes, entendeu o basico
      - 4: Boa qualificacao, cobriu maioria dos pontos
      - 5: Qualificacao completa e natural
      Excecao: Se cliente ja veio qualificado (descreveu exatamente o que quer), nota minima 3.
      Excecao: Em retorno com qualificacao anterior, nota minima 3.

      ### closing_conduct (0-5): Conducao para Fechamento
      - 0: Conversa morreu sem tentativa de avanco
      - 1: Algo vago ("qualquer coisa me chama") sem proposta ativa
      - 2: Tentativa fraca ou no momento errado
      - 3: Propôs acao concreta mas sem urgencia
      - 4: Conduziu bem, propôs acao clara e reforcou
      - 5: Conducao exemplar com urgencia natural e proximo passo claro
      Regra: Se cliente encerrou antes do vendedor ter oportunidade, nota minima 2.

      ### media_usage (0-3): Uso de Midia
      - 0: Cliente perguntou sobre produto e vendedor respondeu so texto
      - 1: Midia inadequada ou generica
      - 2: Foto(s) do produto solicitado
      - 3: Multiplas fotos, ambiente montado, video ou catalogo
      Retorne null se conversa foi puramente sobre pagamento/entrega (N/A).

      ### personalization (0-3): Personalizacao
      - 0: Templates visiveis, nao chamou pelo nome, ignorou info do cliente
      - 1: Chamou pelo nome mas resto generico
      - 2: Usou nome, referenciou o que cliente disse, adaptou sugestoes
      - 3: Altamente pessoal com escuta ativa

      ### unfulfilled_promises: Promessas Nao Cumpridas
      - flagged: true se vendedor prometeu algo ("vou verificar", "ja te envio") e nao cumpriu
      - flagged: false se nao houve promessa ou se foi cumprida
      Frases que ativam: "vou verificar e te retorno", "ja vejo isso", "vou mandar o orcamento", "deixa eu confirmar"

      ### alternatives_offered (0-3): Oferta de Alternativas
      - 0: Produto indisponivel e respondeu "nao temos" sem oferecer nada
      - 1: Mencionou vagamente "tem outros modelos"
      - 2: Sugeriu 1-2 alternativas concretas
      - 3: Alternativas alinhadas, explicou diferencas
      Retorne null se produto solicitado estava disponivel (N/A).

      ### tone_communication (0-3): Tom e Comunicacao
      - 0: Rude, impaciente, ou erros graves de portugues
      - 1: Neutro, seco, monossilabico
      - 2: Cordial, profissional, claro
      - 3: Comunicacao excelente, acolhedor sem ser forcado

      ### return_client_continuity (0-3): Continuidade em Retorno
      - 0: Ignorou historico, refez todas as perguntas
      - 1: Alguma consciencia mas nao usou efetivamente
      - 2: Retomou de onde parou
      - 3: Transicao perfeita, usou historico para agregar valor
      Retorne null se NAO e retorno de cliente (N/A).

      ### cross_sell (0-2): Cross-sell
      - 0: Oportunidade clara desperdicada
      - 1: Mencionou algo complementar superficialmente
      - 2: Sugeriu complementos relevantes naturalmente
      Cross-sell forcado/fora de contexto = 0 com nota negativa.

      ## Regras gerais
      - Sempre justifique com trecho especifico da conversa ou ausencia de comportamento esperado
      - Use null para criterios nao aplicaveis ao contexto
      - feedback_summary: sempre comece com ponto positivo, depois 1-2 melhorias especificas e acionaveis
      - suggested_funnel_stage opcoes EXATAS: Lead, Qualificado, Orcamento, Negociacao, Venda, Perda
    SYSTEM_PROMPT
  end
end
# rubocop:enable Metrics/ClassLength
