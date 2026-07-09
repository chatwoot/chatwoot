module Crm
  module Ai
    class Config
      BOOLEAN = ActiveModel::Type::Boolean.new

      AUTO_MOVE_THRESHOLD = 0.75
      SUGGESTION_THRESHOLD = 0.55
      DEBOUNCE_SECONDS = 15
      MIN_EVALUATION_INTERVAL_SECONDS = 30
      AUTO_MOVE_COOLDOWN_SECONDS = DEBOUNCE_SECONDS
      DEFAULT_STALE_HOURS = 48

      MODEL_SUMMARY = 'gpt-5.4-mini'.freeze
      MODEL_CLASSIFY = 'gpt-5.4-mini'.freeze
      # auto-move usa o mini (custo) + effort high.
      MODEL_AUTO_MOVE = 'gpt-5.4-mini'.freeze
      MODEL_FOLLOWUP = 'gpt-5.4-mini'.freeze
      # E-mail builder copilot (multimodal generate). Full model — sees images/PDFs and writes MJML.
      MODEL_EMAIL = 'gpt-5.4'.freeze

      # REASONING EFFORT por tarefa (modelos seguem mini). Todas as features mini usam 'high':
      # corte de custo (xhigh fatura muito mais token de raciocínio) sem trocar de modelo.
      # Suportados no gpt-5.4-mini: none/low/medium/high/xhigh (validado por probe no endpoint).
      CLASSIFY_REASONING_EFFORT = 'high'.freeze
      SUMMARY_REASONING_EFFORT = 'high'.freeze
      VISION_REASONING_EFFORT = 'high'.freeze
      FOLLOWUP_REASONING_EFFORT = 'high'.freeze
      CALLBACK_REASONING_EFFORT = 'high'.freeze
      # Per-PDF byte cap and per-request PDF count cap for the e-mail copilot (guards download/base64
      # of attached PDFs before they become input_file content parts).
      PDF_BYTE_LIMIT = 32_000_000
      MAX_PDFS_PER_REQUEST = 5

      # AI auto follow-up ("de onde parou") MVP tuning.
      FOLLOWUP_MIN_CONFIDENCE = 0.6
      AUTO_FOLLOWUP_SCAN_CRON_MINUTES = 15
      AUTO_FOLLOWUP_TEMPLATE_CAP_HOURS = 24

      DEFAULT_AUTO_FOLLOWUP = {
        'enabled' => false,
        'trigger_idle_hours' => 6,
        'max_touches' => 3,
        'intervals_hours' => [20, 72, 168],
        'quiet_hours' => { 'start' => 8, 'end' => 20, 'tz' => 'contact' },
        'tone_instructions' => ''
      }.freeze

      # DETECÇÃO DE RETORNO POR DATA ("me liga terça que vem") — o classificador (que já lê TODA
      # mensagem) também extrai um pedido de retorno com data/hora; quando concreto e confiável, cria um
      # LEMBRETE (Crm::FollowUp reminder_only, type=call) na data — que já aparece no calendário e no
      # popup de lembrete. Só cria com confiança alta e data concreta futura (evita falso-positivo de
      # frase vaga). KILL-SWITCH: ENV AI_CALLBACK_DETECTION (default ON).
      CALLBACK_MIN_CONFIDENCE = 0.6
      CALLBACK_MAX_HORIZON_DAYS = 180          # ignora datas muito distantes (provável erro de leitura)
      CALLBACK_DEFAULT_HOUR = 9                 # sem hora/período → início do expediente
      CALLBACK_PERIOD_HOURS = { 'manha' => 9, 'tarde' => 14, 'noite' => 19 }.freeze

      def self.callback_detection_enabled?
        BOOLEAN.cast(ENV.fetch('AI_CALLBACK_DETECTION', true))
      end

      # Toggle POR FUNIL (pipeline.metadata['ai']['callback_enabled'], default LIGADO). Controlado na
      # config de IA do funil e no atalho do calendário. Combina com o kill-switch global da ENV.
      def self.pipeline_callback_enabled?(pipeline)
        pipeline_ai_settings(pipeline)[:callback_enabled] != false
      end

      # MODO do retorno por funil: 'reminder' (só lembrete na tela, default), 'message' (mensagem
      # auto-agendada na data — IA gera/escolhe template, fallback p/ lembrete) ou 'both' (os dois).
      CALLBACK_MODES = %w[reminder message both].freeze

      def self.pipeline_callback_mode(pipeline)
        mode = pipeline_ai_settings(pipeline)[:callback_mode].to_s
        CALLBACK_MODES.include?(mode) ? mode : 'reminder'
      end

      def self.attribute_extraction_enabled?
        raw = ENV.fetch('CRM_AI_ATTR_EXTRACTION', nil)
        enabled? && (raw.blank? || BOOLEAN.cast(raw))
      end

      def self.pipeline_attribute_extraction_enabled?(pipeline)
        BOOLEAN.cast(pipeline_ai_settings(pipeline)[:attribute_extraction_enabled])
      end

      def self.attribute_extraction_prefix(pipeline)
        pipeline_ai_settings(pipeline)[:attribute_prefix].presence || 'sw_'
      end

      def self.attribute_extraction_min_confidence(pipeline)
        raw = pipeline_ai_settings(pipeline)[:attribute_min_confidence].presence || 0.6
        Float(raw).clamp(0.0, 1.0)
      rescue ArgumentError, TypeError
        0.6
      end

      # Timezone EFETIVO para ancorar "amanhã 10h" e gravar o lembrete: contato
      # (additional_attributes['timezone']) → país do contato → account.reporting_timezone →
      # default configurável (ENV['CRM_DEFAULT_TIMEZONE'] ou 'America/Sao_Paulo'). Espelha o
      # AutoFollowupPlanner (quiet hours) para consistência. Sempre devolve um nome de tz VÁLIDO.
      def self.resolved_timezone(account:, contact: nil)
        Crm::Timezone::Resolver.new(contact: contact, account: account).name_or_default
      end

      # Media enrichment (PR13.1): audio via transcription, image via vision caption.
      # whisper-1: aceita OGG/Opus (.oga — formato de voz do WhatsApp/WAHA), m4a (iOS/Instagram), mp3,
      # wav, webm. O gpt-4o-mini-transcribe REJEITA oga/ogg ("Unsupported file format oga", HTTP 400),
      # então quebrava a transcrição de áudio de WhatsApp. Override por ENV p/ trocar sem deploy.
      TRANSCRIBE_MODEL = ENV.fetch('CRM_AI_TRANSCRIBE_MODEL', 'whisper-1').freeze
      VISION_MODEL = 'gpt-5.4-mini'.freeze
      TRANSCRIPTION_BYTE_LIMIT = 25_000_000
      IMAGE_BYTE_LIMIT = 18_000_000
      # TTS (espelhamento de áudio — Onda 2c): voz a partir do texto da resposta. Saída `opus` = formato
      # de voz nativo do WhatsApp (toca como áudio de voz, não anexo). Override por ENV.
      TTS_MODEL = ENV.fetch('CRM_AI_TTS_MODEL', 'gpt-4o-mini-tts').freeze
      TTS_CHAR_LIMIT = 1200 # cap de entrada (custo/latência); a resposta do operate costuma ser curta
      MAX_MEDIA_ENRICH_PER_EVAL = 12
      TRANSCRIPT_MAX_CHARS = 1500
      CAPTION_MAX_CHARS = 400

      def self.enabled?
        ::Crm::Config.enabled? && BOOLEAN.cast(ENV.fetch('CRM_AI_ENABLED', false))
      end

      def self.media_enabled?
        enabled? && BOOLEAN.cast(ENV.fetch('CRM_AI_MEDIA_ENABLED', true))
      end

      def self.pipeline_ai_settings(pipeline)
        (pipeline.metadata || {}).fetch('ai', {}).to_h.with_indifferent_access
      end

      def self.stage_ai_criteria(stage)
        (stage.metadata || {}).fetch('ai_criteria', '').to_s.strip
      end

      # Effective AI auto follow-up config for a pipeline. Pipeline-level
      # metadata.ai.auto_followup overrides the defaults; +enabled+ is always
      # cast to a real boolean so the planner/runner/scan-job can branch safely.
      def self.auto_followup_settings(pipeline)
        cfg = DEFAULT_AUTO_FOLLOWUP.merge(pipeline_ai_settings(pipeline).fetch('auto_followup', {}).to_h)
        cfg['enabled'] = BOOLEAN.cast(cfg['enabled'])
        cfg.with_indifferent_access
      end

      # Don't re-hand-off the same conversation within this window (loop/spam guard).
      HANDOFF_COOLDOWN_SECONDS = 6 * 60 * 60
      # TTL do convite R3: fecha ciclos esquecidos sem re-notificar nem escalar.
      HANDOFF_INVITE_TTL_SECONDS = 24 * 60 * 60
      HANDOFF_PICKUP_THRESHOLD_SECONDS = 15 * 60
      HANDOFF_MODES = %w[direct round_robin].freeze
      HANDOFF_POOL_TYPES = %w[inbox user].freeze
      HANDOFF_ESCALATION_ACTIONS = %w[renotify escalate].freeze
      HANDOFF_RENOTIFY_MAX = 8
      # Fluxo do handoff: r2_direct = atribui direto (comportamento legado);
      # r3_invite = convida (participante + notificação) sem atribuir/calar o bot.
      HANDOFF_FLOW_MODES = %w[r2_direct r3_invite].freeze

      # Effective handoff config for a card's current stage. Stage-level config
      # overrides pipeline-level defaults so a funnel can set a baseline and a
      # stage can refine it.
      def self.handoff_settings(stage, pipeline)
        pipeline_cfg = pipeline_ai_settings(pipeline).fetch('handoff', {}).to_h
        stage_cfg = (stage&.metadata || {}).fetch('ai_handoff', {}).to_h
        cfg = pipeline_cfg.merge(stage_cfg)
        mode = handoff_selector(cfg)
        pickup_threshold_seconds = handoff_pickup_threshold_seconds(cfg)
        escalation_user_id = handoff_escalation_user_id(cfg)
        legacy_handoff_settings(cfg, mode, pickup_threshold_seconds, escalation_user_id)
          .merge(pool_handoff_settings(cfg, pickup_threshold_seconds, escalation_user_id))
          .with_indifferent_access
      end

      def self.legacy_handoff_settings(cfg, mode, pickup_threshold_seconds, escalation_user_id)
        {
          enabled: BOOLEAN.cast(cfg['enabled']),
          mode: mode,
          selector_mode: handoff_selector_mode(cfg, mode),
          handoff_mode: HANDOFF_FLOW_MODES.include?(cfg['handoff_mode']) ? cfg['handoff_mode'] : 'r2_direct',
          trigger: cfg['trigger'].to_s.strip,
          prefer_online: cfg.key?('prefer_online') ? BOOLEAN.cast(cfg['prefer_online']) : true,
          invite_ttl_seconds: handoff_invite_ttl_seconds(cfg),
          pickup_threshold_seconds: pickup_threshold_seconds,
          escalation_user_id: escalation_user_id
        }
      end
      private_class_method :legacy_handoff_settings

      def self.pool_handoff_settings(cfg, pickup_threshold_seconds, escalation_user_id)
        {
          pool_type: handoff_pool_type(cfg),
          pool_id: handoff_pool_id(cfg),
          renotify_after_seconds: handoff_renotify_after_seconds(cfg, pickup_threshold_seconds),
          escalation_action: handoff_escalation_action(cfg, escalation_user_id)
        }
      end
      private_class_method :pool_handoff_settings

      def self.handoff_invite_ttl_seconds(cfg)
        raw = cfg['invite_ttl_seconds'].to_s.strip
        parsed = raw.match?(/\A\d+\z/) ? raw.to_i : 0
        parsed.positive? ? parsed : HANDOFF_INVITE_TTL_SECONDS
      end

      def self.handoff_pickup_threshold_seconds(cfg)
        value = cfg['pickup_threshold_seconds']
        return HANDOFF_PICKUP_THRESHOLD_SECONDS unless value.to_s.match?(/\A\d+\z/)

        seconds = value.to_i
        seconds.positive? ? seconds : HANDOFF_PICKUP_THRESHOLD_SECONDS
      end

      def self.handoff_escalation_user_id(cfg)
        value = cfg['escalation_user_id']
        return value if value.is_a?(Integer) && value.positive?
        return unless value.is_a?(String) && value.match?(/\A\d+\z/)

        user_id = value.to_i
        user_id.positive? ? user_id : nil
      end

      def self.handoff_selector(cfg)
        HANDOFF_MODES.include?(cfg['mode']) ? cfg['mode'] : 'round_robin'
      end
      private_class_method :handoff_selector

      def self.handoff_selector_mode(cfg, mode)
        HANDOFF_MODES.include?(cfg['selector_mode']) ? cfg['selector_mode'] : mode
      end
      private_class_method :handoff_selector_mode

      def self.handoff_pool_type(cfg)
        HANDOFF_POOL_TYPES.include?(cfg['pool_type']) ? cfg['pool_type'] : 'inbox'
      end
      private_class_method :handoff_pool_type

      def self.handoff_pool_id(cfg)
        value = cfg['pool_id']
        return value if value.is_a?(Integer) && value.positive?
        return unless value.is_a?(String) && value.match?(/\A\d+\z/)

        pool_id = value.to_i
        pool_id.positive? ? pool_id : nil
      end
      private_class_method :handoff_pool_id

      def self.handoff_renotify_after_seconds(cfg, fallback)
        value = cfg['renotify_after_seconds']
        return fallback unless value.to_s.match?(/\A\d+\z/)

        seconds = value.to_i
        seconds.positive? ? seconds : fallback
      end
      private_class_method :handoff_renotify_after_seconds

      def self.handoff_escalation_action(cfg, escalation_user_id)
        action = if HANDOFF_ESCALATION_ACTIONS.include?(cfg['escalation_action'])
                   cfg['escalation_action']
                 else
                   default_escalation_action(escalation_user_id)
                 end
        action == 'escalate' && escalation_user_id.blank? ? 'renotify' : action
      end
      private_class_method :handoff_escalation_action

      def self.default_escalation_action(escalation_user_id) = escalation_user_id.present? ? 'escalate' : 'renotify'
      private_class_method :default_escalation_action
    end
  end
end
