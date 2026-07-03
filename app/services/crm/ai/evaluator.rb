module Crm
  module Ai
    class Evaluator
      Result = Struct.new(:status, :suggestion, :error, keyword_init: true)

      def initialize(card:, trigger: 'message')
        @card = card
        @account = card.account
        @trigger = trigger
      end

      def perform
        return Result.new(status: :skipped, error: 'ai_disabled') unless Config.enabled?
        return Result.new(status: :skipped, error: 'credentials_missing') unless credential_resolver.configured?
        return Result.new(status: :skipped, error: 'pipeline_ai_disabled') unless pipeline_ai_enabled?
        return Result.new(status: :skipped, error: 'debounced') if debounced? && @trigger != 'manual'
        return Result.new(status: :skipped, error: 'card_not_open') unless @card.open?

        classification = classify_stage
        result = apply_classification(classification)
        run_handoff(classification)
        run_callback(classification)
        run_attribute_extraction(classification)
        result
      rescue ResponsesClient::Error => e
        Result.new(status: :failed, error: e.message)
      rescue JSON::ParserError
        Result.new(status: :failed, error: 'invalid_llm_json')
      end

      private

      def credential_resolver
        @credential_resolver ||= CredentialResolver.new(account: @account)
      end

      def pipeline_ai_enabled?
        settings = Config.pipeline_ai_settings(@card.pipeline)
        settings[:enabled] != false
      end

      def debounced?
        last_evaluated_at = ai_metadata['last_evaluated_at']
        return false if last_evaluated_at.blank?

        Time.parse(last_evaluated_at) > Config::DEBOUNCE_SECONDS.seconds.ago
      rescue ArgumentError
        false
      end

      def classify_stage
        MediaEnricher.new(card: @card).perform if Config.media_enabled?
        # cache_key_scope: :feature — o prefixo do classify é conta-agnóstico (StageClassifier#instructions),
        # então roteamos por feature só (sem account) p/ consolidar o hit-rate de cache entre contas.
        client = ResponsesClient.new(
          credential: credential_resolver.resolve,
          feature: 'avaliacao_card', account: @account, pipeline: @card.pipeline,
          cache_key_scope: :feature
        )
        context = ContextBuilder.new(card: @card).perform
        model = auto_move_allowed? ? Config::MODEL_AUTO_MOVE : Config::MODEL_CLASSIFY
        effort = Config::CLASSIFY_REASONING_EFFORT

        StageClassifier.new(
          card: @card,
          client: client,
          stages: stages,
          context: context,
          model: model,
          reasoning_effort: effort,
          handoff_enabled: handoff_config[:enabled],
          handoff_trigger: handoff_config[:trigger],
          eligible_agents: eligible_agent_names,
          attribute_schema: attribute_schema
        ).perform
      end

      def handoff_config
        @handoff_config ||= Config.handoff_settings(@card.stage, @card.pipeline)
      end

      def eligible_agent_names
        return [] unless handoff_config[:enabled]

        inbox = @card.primary_conversation&.inbox
        inbox ? inbox.members.pluck(:name) : []
      end

      # Independent of the stage move. Guarded inside the executor; never let a
      # handoff failure break the evaluation result.
      def run_handoff(classification)
        return unless handoff_config[:enabled]

        HandoffExecutor.new(card: @card, handoff: classification[:handoff], trigger: @trigger).perform
      rescue StandardError => e
        Rails.logger.error("[CRM AI handoff] #{e.class}: #{e.message}")
      end

      # Cria/atualiza um lembrete quando a IA detectou um pedido de retorno com data concreta.
      # Best-effort: o CallbackScheduler já engole erros, mas guardamos aqui também por simetria —
      # nunca deixa a detecção de retorno quebrar a avaliação do card.
      def run_callback(classification)
        return unless Config.callback_detection_enabled?
        return unless Config.pipeline_callback_enabled?(@card.pipeline)

        Crm::FollowUps::CallbackScheduler.new(card: @card, callback: classification[:callback_request]).perform
      rescue StandardError => e
        Rails.logger.error("[CRM AI callback] #{e.class}: #{e.message}")
      end

      def run_attribute_extraction(classification)
        return unless attribute_extraction_enabled?

        AttributeExtractorApplier.new(
          card: @card,
          extracted_attributes: classification[:extracted_attributes],
          prefix: Config.attribute_extraction_prefix(@card.pipeline),
          min_confidence: Config.attribute_extraction_min_confidence(@card.pipeline)
        ).perform
      rescue StandardError => e
        Rails.logger.error("[CRM AI attribute extraction] #{e.class}: #{e.message}")
      end

      def apply_classification(classification)
        touch_evaluation_metadata(classification)
        target_stage = stages.find { |stage| stage.id == classification[:suggested_stage_id].to_i }
        return Result.new(status: :skipped, error: 'unknown_stage') if target_stage.blank?
        return Result.new(status: :skipped, error: 'same_stage') if target_stage.id == @card.stage_id

        confidence = classification[:confidence].to_f
        if auto_move_allowed? && confidence >= Config::AUTO_MOVE_THRESHOLD && stage_criteria_present?(target_stage)
          suggestion = SuggestionRecorder.new(
            card: @card,
            from_stage: @card.stage,
            to_stage: target_stage,
            confidence: confidence,
            reasoning: classification[:reasoning],
            model_used: classification[:model_used],
            status: :auto_applied,
            metadata: { trigger: @trigger }
          ).perform

          SuggestionApplier.new(card: @card, suggestion: suggestion, actor: nil, auto: true).perform
          Result.new(status: :auto_moved, suggestion: suggestion)
        elsif confidence >= Config::SUGGESTION_THRESHOLD
          suggestion = SuggestionRecorder.new(
            card: @card,
            from_stage: @card.stage,
            to_stage: target_stage,
            confidence: confidence,
            reasoning: classification[:reasoning],
            model_used: classification[:model_used],
            status: :pending,
            metadata: { trigger: @trigger }
          ).perform
          Result.new(status: :suggested, suggestion: suggestion)
        else
          Result.new(status: :below_threshold)
        end
      end

      def auto_move_allowed?
        settings = Config.pipeline_ai_settings(@card.pipeline)
        return false unless settings[:auto_move_enabled]

        return true if Config::AUTO_MOVE_COOLDOWN_SECONDS <= 0

        return false if ai_metadata['last_auto_move_at'].present? &&
                        Time.parse(ai_metadata['last_auto_move_at']) > Config::AUTO_MOVE_COOLDOWN_SECONDS.seconds.ago

        true
      rescue ArgumentError
        false
      end

      def stage_criteria_present?(stage)
        Config.stage_ai_criteria(stage).present?
      end

      def stages
        @stages ||= @card.pipeline.stages.order(:position, :id).to_a
      end

      def attribute_extraction_enabled?
        return @attribute_extraction_enabled if defined?(@attribute_extraction_enabled)

        @attribute_extraction_enabled = Config.attribute_extraction_enabled? &&
                                        Config.pipeline_attribute_extraction_enabled?(@card.pipeline)
      end

      def attribute_schema
        return { contact: [], conversation: [] } unless attribute_extraction_enabled?

        @attribute_schema ||= AttributeSchemaBuilder.new(
          account: @account,
          prefix: Config.attribute_extraction_prefix(@card.pipeline)
        ).perform
      end

      def ai_metadata
        (@card.metadata || {}).fetch('ai', {}).to_h
      end

      def touch_evaluation_metadata(classification)
        metadata = (@card.metadata || {}).deep_dup
        metadata['ai'] = (metadata['ai'] || {}).merge(
          'last_evaluated_at' => Time.current.iso8601,
          'last_model_used' => classification[:model_used],
          'last_trigger' => @trigger
        )
        attributes = { metadata: metadata }
        apply_ai_value!(metadata['ai'], classification[:value], attributes)
        @card.update!(attributes)
      end

      # Auto-fill the deal value detected in the conversation, writing value_cents
      # directly (product decision: "autopreenche sempre"). The ONLY guard is a
      # human takeover: once someone edits the value manually (value_source =
      # 'human'), a later eval must never undo that correction.
      def apply_ai_value!(ai_metadata, value, attributes)
        value = value.respond_to?(:with_indifferent_access) ? value.with_indifferent_access : value
        return if value.blank? || value[:amount_cents].blank? || value[:currency].blank?
        return if ai_metadata['value_source'] == 'human'

        amount = value[:amount_cents].to_i
        currency = value[:currency].to_s.upcase
        return if amount == @card.value_cents && currency == @card.currency

        attributes[:value_cents] = amount
        attributes[:currency] = currency
        ai_metadata['value_source'] = 'ai'
        ai_metadata['value_filled_at'] = Time.current.iso8601
      end
    end
  end
end
