# frozen_string_literal: true

module Aloo
  class Assistant < ApplicationRecord
    self.table_name = 'aloo_assistants'

    include Aloo::AccountScoped # CRITICAL: Always scope by account

    # Voice configuration constants
    VALID_REPLY_MODES = %w[text_only voice_only text_and_voice].freeze
    VALID_TTS_PROVIDERS = %w[elevenlabs].freeze
    VALID_TRANSCRIPTION_PROVIDERS = %w[openai].freeze
    DEFAULT_TRANSCRIPTION_MODEL = 'whisper-1'
    DEFAULT_TTS_MODEL = 'eleven_multilingual_v2'

    # Voice config store accessors for convenient access
    store_accessor :voice_config,
                   :transcription_provider,
                   :transcription_model,
                   :tts_provider,
                   :elevenlabs_voice_id,
                   :elevenlabs_model_id,
                   :elevenlabs_stability,
                   :elevenlabs_similarity_boost,
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
    has_many :conversation_contexts,
             class_name: 'Aloo::ConversationContext',
             foreign_key: 'aloo_assistant_id',
             dependent: :destroy,
             inverse_of: :assistant
    has_many :memories,
             class_name: 'Aloo::Memory',
             foreign_key: 'aloo_assistant_id',
             dependent: :destroy,
             inverse_of: :assistant
    has_many :traces,
             class_name: 'Aloo::Trace',
             foreign_key: 'aloo_assistant_id',
             dependent: :nullify,
             inverse_of: :assistant
    has_many :messages, as: :sender, dependent: :nullify
    has_many :voice_usage_records,
             class_name: 'Aloo::VoiceUsageRecord',
             foreign_key: 'aloo_assistant_id',
             dependent: :destroy,
             inverse_of: :assistant
    # Deferred to v2: has_many :custom_tools

    # Personality settings (user-configurable)
    TONES = %w[professional friendly casual formal].freeze
    FORMALITY_LEVELS = %w[high medium low].freeze
    EMPATHY_LEVELS = %w[high medium low].freeze
    VERBOSITY_LEVELS = %w[concise balanced detailed].freeze
    EMOJI_USAGE_LEVELS = %w[none minimal moderate].freeze
    GREETING_STYLES = %w[warm direct custom].freeze

    # Arabic dialects by country
    ARABIC_DIALECTS = {
      'EG' => { name: 'Egyptian', prompt: 'Respond in Egyptian Arabic (مصري). Use Egyptian expressions and phrases.' },
      'SA' => { name: 'Saudi', prompt: 'Respond in Saudi Arabic (سعودي). Use Saudi expressions and phrases.' },
      'AE' => { name: 'Emirati', prompt: 'Respond in Emirati Arabic (إماراتي). Use Emirati expressions and phrases.' },
      'KW' => { name: 'Kuwaiti', prompt: 'Respond in Kuwaiti Arabic (كويتي). Use Kuwaiti expressions and phrases.' },
      'QA' => { name: 'Qatari', prompt: 'Respond in Qatari Arabic (قطري). Use Qatari expressions and phrases.' },
      'BH' => { name: 'Bahraini', prompt: 'Respond in Bahraini Arabic (بحريني). Use Bahraini expressions and phrases.' },
      'OM' => { name: 'Omani', prompt: 'Respond in Omani Arabic (عماني). Use Omani expressions and phrases.' },
      'JO' => { name: 'Jordanian', prompt: 'Respond in Jordanian Arabic (أردني). Use Jordanian expressions and phrases.' },
      'LB' => { name: 'Lebanese', prompt: 'Respond in Lebanese Arabic (لبناني). Use Lebanese expressions and phrases.' },
      'SY' => { name: 'Syrian', prompt: 'Respond in Syrian Arabic (سوري). Use Syrian expressions and phrases.' },
      'IQ' => { name: 'Iraqi', prompt: 'Respond in Iraqi Arabic (عراقي). Use Iraqi expressions and phrases.' },
      'MA' => { name: 'Moroccan', prompt: 'Respond in Moroccan Arabic (مغربي/دارجة). Use Moroccan expressions.' },
      'DZ' => { name: 'Algerian', prompt: 'Respond in Algerian Arabic (جزائري). Use Algerian expressions and phrases.' },
      'TN' => { name: 'Tunisian', prompt: 'Respond in Tunisian Arabic (تونسي). Use Tunisian expressions and phrases.' },
      'LY' => { name: 'Libyan', prompt: 'Respond in Libyan Arabic (ليبي). Use Libyan expressions and phrases.' },
      'SD' => { name: 'Sudanese', prompt: 'Respond in Sudanese Arabic (سوداني). Use Sudanese expressions and phrases.' },
      'PS' => { name: 'Palestinian', prompt: 'Respond in Palestinian Arabic (فلسطيني). Use Palestinian expressions and phrases.' },
      'MSA' => { name: 'Modern Standard', prompt: 'Respond in Modern Standard Arabic (فصحى). Use formal Arabic.' }
    }.freeze

    validates :name, presence: true, uniqueness: { scope: :account_id }
    validates :tone, inclusion: { in: TONES }
    validates :formality, inclusion: { in: FORMALITY_LEVELS }
    validates :empathy_level, inclusion: { in: EMPATHY_LEVELS }
    validates :verbosity, inclusion: { in: VERBOSITY_LEVELS }
    validates :emoji_usage, inclusion: { in: EMOJI_USAGE_LEVELS }
    validates :greeting_style, inclusion: { in: GREETING_STYLES }
    validates :dialect, inclusion: { in: ARABIC_DIALECTS.keys }, allow_blank: true
    validates :language, inclusion: { in: Aloo::SUPPORTED_LANGUAGES.keys }
    validate :validate_voice_config, if: :voice_enabled?

    scope :active, -> { where(active: true) }

    # Build the personality prompt based on user settings
    def personality_prompt
      Aloo::PersonalityBuilder.new(self).build
    end

    # Get the language instruction for the LLM
    def language_instruction
      return '' if language == 'en' && dialect.blank?

      if language == 'ar' && dialect.present?
        ARABIC_DIALECTS.dig(dialect, :prompt) || ''
      else
        "Respond in #{language_name}."
      end
    end

    def language_name
      Aloo::SUPPORTED_LANGUAGES.dig(language, :name) || 'English'
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

    def feature_faq_enabled?
      admin_config['feature_faq'] == true
    end

    def feature_memory_enabled?
      admin_config['feature_memory'] == true
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

    # Full system prompt combining base + personality + guardrails
    def full_system_prompt
      [
        system_prompt,
        personality_prompt,
        response_guidelines,
        guardrails,
        language_instruction
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
      elevenlabs_model_id.presence || DEFAULT_TTS_MODEL
    end

    def effective_reply_mode
      reply_mode.presence || 'text_and_voice'
    end

    def voice_reply_enabled?
      voice_enabled? && elevenlabs_voice_id.present?
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
