# frozen_string_literal: true

module Aloo
  class Assistant < ApplicationRecord
    self.table_name = 'aloo_assistants'

    include Aloo::AccountScoped # CRITICAL: Always scope by account

    # Voice configuration constants
    VALID_REPLY_MODES = %w[text_only voice_only text_and_voice].freeze
    VALID_TTS_PROVIDERS = %w[elevenlabs openai].freeze
    VALID_TRANSCRIPTION_PROVIDERS = %w[openai].freeze
    DEFAULT_TRANSCRIPTION_MODEL = 'whisper-1'
    DEFAULT_TTS_MODEL = 'eleven_v3'

    # Voice config store accessors for convenient access
    store_accessor :voice_config,
                   :transcription_provider,
                   :transcription_model,
                   :tts_provider,
                   :elevenlabs_voice_id,
                   :elevenlabs_model_id,
                   :elevenlabs_stability,
                   :elevenlabs_similarity_boost,
                   :openai_voice,
                   :openai_model_id,
                   :reply_mode

    has_many :assistant_inboxes,
             class_name: 'Aloo::AssistantInbox',
             foreign_key: 'aloo_assistant_id',
             dependent: :destroy,
             inverse_of: :assistant
    has_many :inboxes, through: :assistant_inboxes
    has_many :documents,
             class_name: 'Aloo::Document',
             foreign_key: 'aloo_assistant_id',
             dependent: :destroy,
             inverse_of: :assistant
    has_many :embeddings,
             class_name: 'Aloo::Embedding',
             foreign_key: 'aloo_assistant_id',
             dependent: :destroy,
             inverse_of: :assistant
    has_many :messages, as: :sender, dependent: :nullify
    has_many :created_carts, as: :created_by, class_name: 'Cart', dependent: :nullify
    # Deferred to v2: has_many :custom_tools

    # Personality settings (user-configurable)
    TONES = %w[professional friendly casual formal].freeze
    FORMALITY_LEVELS = %w[high medium low].freeze
    EMPATHY_LEVELS = %w[high medium low].freeze
    VERBOSITY_LEVELS = %w[concise balanced detailed].freeze
    EMOJI_USAGE_LEVELS = %w[none minimal moderate].freeze
    GREETING_STYLES = %w[warm direct custom].freeze

    validates :name, presence: true
    validates :tone, inclusion: { in: TONES }
    validates :formality, inclusion: { in: FORMALITY_LEVELS }
    validates :empathy_level, inclusion: { in: EMPATHY_LEVELS }
    validates :verbosity, inclusion: { in: VERBOSITY_LEVELS }
    validates :emoji_usage, inclusion: { in: EMOJI_USAGE_LEVELS }
    validates :greeting_style, inclusion: { in: GREETING_STYLES }
    validate :validate_voice_config, if: :voice_enabled?
    scope :active, -> { where(active: true) }

    # Build the personality prompt based on user settings
    def personality_prompt
      Aloo::PersonalityBuilder.new(self).build
    end

    # Admin config accessors with defaults
    def model
      admin_config['model'] || 'gpt-4.1-mini'
    end

    def temperature
      admin_config['temperature'] || 0.7
    end

    def max_tokens
      admin_config['max_tokens'] || 1024
    end

    # MCP tool feature flags (default to true for backward compatibility)
    def feature_handoff_enabled?
      admin_config['feature_handoff'] != false
    end

    def feature_resolve_enabled?
      admin_config['feature_resolve'] != false
    end

    def feature_snooze_enabled?
      admin_config['feature_snooze'] != false
    end

    def feature_labels_enabled?
      admin_config['feature_labels'] != false
    end

    # Catalog tool feature flag (single flag for all catalog tools)
    def feature_catalog_access_enabled?
      admin_config['feature_catalog_access'] != false
    end

    # Macros tool feature flag
    def feature_macros_enabled?
      admin_config['feature_macros'] != false
    end

    # Calendly tool feature flag
    def feature_calendly_enabled? = admin_config['feature_calendly'] != false

    # Full system prompt combining base + personality + guardrails
    def full_system_prompt
      [
        system_prompt,
        personality_prompt,
        response_guidelines,
        guardrails
      ].compact_blank.join("\n\n")
    end

    # Required for message sender compatibility
    def available_name
      name
    end

    # Serialization for message sender display
    # Used when assistant is the sender of a message
    def push_event_data(_inbox = nil)
      {
        id: id,
        name: name,
        avatar_url: nil,
        type: 'aloo_assistant'
      }
    end

    # Serialization for webhook payloads
    # Used by WebhookListener when dispatching typing events
    def webhook_data
      {
        id: id,
        name: name,
        type: 'aloo_assistant'
      }
    end

    # Required for ActionCableListener compatibility when dispatching typing events
    # Returns nil since assistants don't have their own pubsub token
    def pubsub_token
      nil
    end

    # Voice configuration helpers
    def effective_transcription_model
      transcription_model.presence || DEFAULT_TRANSCRIPTION_MODEL
    end

    def effective_tts_model
      case tts_provider
      when 'openai'
        openai_model_id.presence || 'tts-1'
      else
        elevenlabs_model_id.presence || DEFAULT_TTS_MODEL
      end
    end

    def effective_reply_mode
      reply_mode.presence || 'text_and_voice'
    end

    def voice_reply_enabled?
      return false unless voice_enabled?

      case tts_provider
      when 'openai'
        true # OpenAI uses named voices (alloy, nova, etc.), always available
      else
        elevenlabs_voice_id.present?
      end
    end

    def voice_transcription_enabled?
      voice_enabled?
    end

    private

    def validate_voice_config
      return unless voice_enabled?

      errors.add(:voice_config, "invalid tts_provider: #{tts_provider}") if tts_provider.present? && !VALID_TTS_PROVIDERS.include?(tts_provider)

      return if transcription_provider.blank?
      return if VALID_TRANSCRIPTION_PROVIDERS.include?(transcription_provider)

      errors.add(:voice_config, "invalid transcription_provider: #{transcription_provider}")
    end
  end
end
