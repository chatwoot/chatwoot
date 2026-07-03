module Crm
  module Ai
    class StageClassifier
      EXTRACTED_ATTR_ITEM = {
        type: 'object',
        properties: {
          key: { type: 'string', description: 'Chave exata do atributo conforme attribute_schema.' },
          value: { type: %w[string number boolean], description: 'Valor limpo extraído da conversa.' },
          confidence: { type: 'number', minimum: 0, maximum: 1 },
          evidence: { type: 'string', maxLength: 300, description: 'Trecho curto que sustenta a extração.' }
        },
        required: %w[key value confidence evidence],
        additionalProperties: false
      }.freeze

      CLASSIFICATION_SCHEMA = {
        name: 'stage_classification',
        schema: {
          type: 'object',
          properties: {
            suggested_stage_id: { type: 'integer' },
            confidence: { type: 'number', minimum: 0, maximum: 1 },
            reasoning: { type: 'string', maxLength: 500 },
            value: {
              type: %w[object null],
              description: 'Valor do negócio citado na conversa. null se nenhum valor for mencionado.',
              properties: {
                amount_cents: { type: 'integer', minimum: 0, description: 'Valor em centavos (ex.: R$ 1.500,00 => 150000).' },
                currency: { type: 'string', description: 'Código ISO da moeda (ex.: BRL, USD).' }
              },
              required: %w[amount_cents currency],
              additionalProperties: false
            },
            handoff: {
              type: %w[object null],
              description: 'Preencha quando a conversa atender o gatilho de handoff informado. null caso contrário.',
              properties: {
                intent: {
                  type: 'string',
                  enum: %w[continuar transferir consultar],
                  description: 'Intenção do cliente quanto a falar com humano: "transferir" (quer assumir com atendente agora), ' \
                               '"consultar" (dúvida pontual p/ especialista, sem assumir o atendimento) ou "continuar" (segue no atendimento normal).'
                },
                should_handoff: { type: 'boolean', description: 'true SOMENTE quando intent="transferir"; senão false.' },
                reason: { type: 'string', maxLength: 300, description: 'Motivo curto do handoff.' },
                suggested_agent: { type: %w[string null], description: 'Nome do agente citado/pedido na conversa, se houver; senão null.' }
              },
              required: %w[intent should_handoff reason suggested_agent],
              additionalProperties: false
            },
            callback_request: {
              type: %w[object null],
              description: 'Preencha SOMENTE quando o cliente pedir um retorno/contato numa DATA ou HORA concreta. null caso contrário.',
              properties: {
                detected: { type: 'boolean', description: 'true se há pedido de retorno com data/hora concreta.' },
                requested_at: { type: %w[string null], description: 'Data/hora LOCAL resolvida no formato "YYYY-MM-DDTHH:MM" (sem fuso). null se não der para resolver uma data concreta.' },
                requested_at_text: { type: %w[string null], description: 'Trecho original do pedido (ex.: "me liga terça que vem de tarde").' },
                confidence: { type: 'number', minimum: 0, maximum: 1, description: 'Confiança de que há um pedido de retorno com data concreta.' }
              },
              required: %w[detected requested_at requested_at_text confidence],
              additionalProperties: false
            },
            extracted_attributes: {
              type: 'object',
              description: 'Atributos customizados extraídos com evidência clara. Use arrays vazios se não houver extrações.',
              properties: {
                contact: { type: 'array', items: EXTRACTED_ATTR_ITEM },
                conversation: { type: 'array', items: EXTRACTED_ATTR_ITEM }
              },
              required: %w[contact conversation],
              additionalProperties: false
            }
          },
          required: %w[suggested_stage_id confidence reasoning value handoff callback_request extracted_attributes],
          additionalProperties: false
        }
      }.freeze

      def initialize(card:, client:, stages:, context:, model: Config::MODEL_CLASSIFY, reasoning_effort: 'low',
                     handoff_enabled: false, handoff_trigger: '', eligible_agents: [], attribute_schema: { contact: [], conversation: [] })
        @card = card
        @client = client
        @stages = stages
        @context = context
        @model = model
        @reasoning_effort = reasoning_effort
        @handoff_enabled = handoff_enabled
        @handoff_trigger = handoff_trigger.to_s.strip
        @eligible_agents = Array(eligible_agents)
        @attribute_schema = attribute_schema
      end

      def perform
        response = @client.create(
          model: @model,
          instructions: instructions,
          input: user_input,
          schema: CLASSIFICATION_SCHEMA,
          reasoning_effort: @reasoning_effort
        )

        JSON.parse(response[:text]).with_indifferent_access.merge(
          model_used: @model,
          usage: response[:usage],
          response_id: response[:response_id]
        )
      end

      private

      # Prefixo ESTÁVEL (call-invariant) p/ prompt caching — constante congelada em ClassifierPrompt::TEXT.
      # Estágios/critérios DINÂMICOS ficam no user_input, nunca no prefixo. Ver ClassifierPrompt.
      def instructions
        ClassifierPrompt::TEXT
      end

      def user_input
        {
          card: {
            id: @card.id,
            title: @card.title,
            current_stage_id: @context[:current_stage][:id],
            current_stage_name: @context[:current_stage][:name]
          },
          stages: @stages.map { |stage| stage_payload(stage) },
          conversation_summary: @context[:summary],
          recent_messages: @context[:recent_messages],
          handoff_enabled: @handoff_enabled,
          handoff_trigger: @handoff_trigger,
          eligible_agents: @eligible_agents,
          now_local: @context.dig(:temporal, :now_local),
          weekday: @context.dig(:temporal, :weekday),
          timezone: @context.dig(:temporal, :timezone),
          default_hour: @context.dig(:temporal, :default_hour) || 9,
          attribute_schema: @attribute_schema
        }.to_json
      end

      def stage_payload(stage)
        {
          id: stage.id,
          name: stage.name,
          criteria: Config.stage_ai_criteria(stage)
        }
      end
    end
  end
end
