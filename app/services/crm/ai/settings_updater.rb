module Crm
  module Ai
    class SettingsUpdater
      def initialize(pipeline:, params:, stage_criteria: {}, stage_handoff: {})
        @pipeline = pipeline
        @params = params.to_h.with_indifferent_access
        @stage_criteria = stage_criteria.to_h
        @stage_handoff = stage_handoff.to_h
      end

      def perform
        update_pipeline_metadata!
        update_stage_metadata!
        @pipeline
      end

      private

      def update_pipeline_metadata!
        metadata = (@pipeline.metadata || {}).deep_dup
        ai = metadata['ai'] || {}
        # Merge PARCIAL por chave: só sobrescreve o que veio nos params. Permite que o atalho do
        # calendário envie SÓ callback_enabled sem zerar enabled/auto_move/stale (o painel do funil
        # segue mandando tudo, sem regressão). Espelha a salvaguarda que já existia p/ auto_followup.
        ai['enabled'] = cast_boolean(@params[:enabled], default: true) if @params.key?(:enabled)
        ai['auto_move_enabled'] = cast_boolean(@params[:auto_move_enabled], default: false) if @params.key?(:auto_move_enabled)
        if @params.key?(:attribute_extraction_enabled)
          ai['attribute_extraction_enabled'] = cast_boolean(
            @params[:attribute_extraction_enabled],
            default: false
          )
        end
        ai['callback_enabled'] = cast_boolean(@params[:callback_enabled], default: true) if @params.key?(:callback_enabled)
        ai['callback_mode'] = normalize_callback_mode(@params[:callback_mode]) if @params.key?(:callback_mode)
        ai['stale_hours'] = (@params[:stale_hours].presence || Config::DEFAULT_STALE_HOURS).to_i if @params.key?(:stale_hours)
        ai['auto_followup'] = normalize_auto_followup(@params[:auto_followup]) if @params.key?(:auto_followup)
        ai['handoff'] = normalize_handoff(@params[:handoff], ai['handoff']) if @params.key?(:handoff)
        metadata['ai'] = ai
        @pipeline.update!(metadata: metadata)
      end

      def normalize_auto_followup(params)
        cfg = params.to_h.with_indifferent_access
        {
          'enabled' => cast_boolean(cfg[:enabled], default: false),
          'trigger_idle_hours' => cfg[:trigger_idle_hours].to_i,
          'max_touches' => cfg[:max_touches].to_i,
          'intervals_hours' => Array(cfg[:intervals_hours]).map(&:to_i),
          'quiet_hours' => normalize_quiet_hours(cfg[:quiet_hours]),
          'tone_instructions' => cfg[:tone_instructions].to_s.strip
        }
      end

      def normalize_quiet_hours(params)
        cfg = params.to_h.with_indifferent_access
        {
          'start' => cfg[:start].to_i,
          'end' => cfg[:end].to_i,
          'tz' => cfg[:tz].to_s.strip.presence || 'contact'
        }
      end

      def update_stage_metadata!
        return if @stage_criteria.blank? && @stage_handoff.blank?

        @pipeline.stages.find_each do |stage|
          key = stage.id.to_s
          criteria = @stage_criteria[key]
          handoff = @stage_handoff[key]
          next if criteria.nil? && handoff.nil?

          metadata = (stage.metadata || {}).deep_dup
          metadata['ai_criteria'] = criteria.to_s.strip unless criteria.nil?
          apply_stage_handoff!(metadata, handoff) unless handoff.nil?
          stage.update!(metadata: metadata)
        end
      end

      # `custom:false` é o sinal explícito de "voltar ao padrão do funil": apaga o override
      # da etapa (em vez de gravar um bloco com defaults) para que `Config.handoff_settings`
      # volte a herdar o `ai['handoff']` do pipeline sem sombreá-lo (causa raiz do achado do
      # Codex no PR4b: gravar defaults explícitos por etapa sombreia o default do funil).
      def apply_stage_handoff!(metadata, handoff)
        cfg = handoff.to_h.with_indifferent_access
        if cfg.key?(:custom) && !cast_boolean(cfg[:custom], default: true)
          metadata.delete('ai_handoff')
        else
          metadata['ai_handoff'] = normalize_handoff(handoff, metadata['ai_handoff'])
        end
      end

      # Merge PARCIAL por chave sobre o bloco já gravado: só sobrescreve o que veio no params.
      # Assim o save do painel (que ainda NÃO expõe handoff_mode) não reverte um override
      # r3_invite ligado por outro caminho, e um PATCH parcial não apaga os demais campos.
      # Chaves ausentes no blob antigo caem nos defaults seguros (mesma resolução da leitura).
      def normalize_handoff(handoff, existing = {})
        cfg = handoff.to_h.with_indifferent_access
        result = normalized_handoff_defaults(existing)
        result['enabled'] = cast_boolean(cfg[:enabled], default: false) if cfg.key?(:enabled)
        result['mode'] = normalize_handoff_selector(cfg[:mode]) if cfg.key?(:mode)
        result['handoff_mode'] = normalize_handoff_flow(cfg[:handoff_mode]) if cfg.key?(:handoff_mode)
        result['trigger'] = cfg[:trigger].to_s.strip if cfg.key?(:trigger)
        result['prefer_online'] = cast_boolean(cfg[:prefer_online], default: true) if cfg.key?(:prefer_online)
        result['pickup_threshold_seconds'] = Config.handoff_pickup_threshold_seconds(cfg) if cfg.key?(:pickup_threshold_seconds)
        result['escalation_user_id'] = Config.handoff_escalation_user_id(cfg) if cfg.key?(:escalation_user_id)
        result['pool_type'] = normalize_handoff_pool_type(cfg[:pool_type]) if cfg.key?(:pool_type)
        result['pool_id'] = normalize_positive_integer(cfg[:pool_id]) if cfg.key?(:pool_id)
        result['escalation_action'] = normalize_handoff_escalation_action(cfg[:escalation_action]) if cfg.key?(:escalation_action)
        if cfg.key?(:renotify_after_seconds)
          renotify_after_seconds = normalize_positive_integer(cfg[:renotify_after_seconds])
          renotify_after_seconds ? result['renotify_after_seconds'] = renotify_after_seconds : result.delete('renotify_after_seconds')
        end
        result
      end

      def normalized_handoff_defaults(existing)
        cfg = (existing || {}).to_h.with_indifferent_access
        result = {
          'enabled' => cast_boolean(cfg[:enabled], default: false),
          # selector_mode is a read-time alias of `mode` (Config.handoff_selector_mode
          # mirrors mode when absent); persisting it separately would let it drift from
          # mode and silently override the selector on save. So we never store it.
          'mode' => normalize_handoff_selector(cfg[:mode]),
          'handoff_mode' => normalize_handoff_flow(cfg[:handoff_mode]),
          'trigger' => cfg[:trigger].to_s.strip,
          'prefer_online' => cfg.key?(:prefer_online) ? cast_boolean(cfg[:prefer_online], default: true) : true,
          'pickup_threshold_seconds' => Config.handoff_pickup_threshold_seconds(cfg),
          'escalation_user_id' => Config.handoff_escalation_user_id(cfg),
          'pool_type' => normalize_handoff_pool_type(cfg[:pool_type]),
          'pool_id' => normalize_positive_integer(cfg[:pool_id]),
          'escalation_action' => normalize_handoff_escalation_action(cfg[:escalation_action])
        }
        renotify_after_seconds = normalize_positive_integer(cfg[:renotify_after_seconds])
        result['renotify_after_seconds'] = renotify_after_seconds if renotify_after_seconds
        result
      end

      def normalize_handoff_selector(value)
        Config::HANDOFF_MODES.include?(value) ? value : 'round_robin'
      end

      def normalize_handoff_flow(value)
        Config::HANDOFF_FLOW_MODES.include?(value) ? value : 'r2_direct'
      end

      def normalize_handoff_pool_type(value)
        Config::HANDOFF_POOL_TYPES.include?(value) ? value : 'inbox'
      end

      def normalize_handoff_escalation_action(value)
        Config::HANDOFF_ESCALATION_ACTIONS.include?(value) ? value : 'renotify'
      end

      def normalize_positive_integer(value)
        return value if value.is_a?(Integer) && value.positive?
        return unless value.is_a?(String) && value.match?(/\A\d+\z/)

        parsed = value.to_i
        parsed.positive? ? parsed : nil
      end

      def cast_boolean(value, default:)
        return default if value.nil?

        ActiveModel::Type::Boolean.new.cast(value)
      end

      def normalize_callback_mode(value)
        mode = value.to_s
        Config::CALLBACK_MODES.include?(mode) ? mode : 'reminder'
      end
    end
  end
end
