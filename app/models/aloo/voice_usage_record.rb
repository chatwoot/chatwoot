# frozen_string_literal: true

module Aloo
  class VoiceUsageRecord < ApplicationRecord
    self.table_name = 'aloo_voice_usage_records'

    include Aloo::AccountScoped

    belongs_to :assistant,
               class_name: 'Aloo::Assistant',
               foreign_key: 'aloo_assistant_id',
               inverse_of: :voice_usage_records
    belongs_to :message, optional: true

    OPERATION_TYPES = %w[transcription synthesis].freeze
    PROVIDERS = %w[openai elevenlabs].freeze
    STATUSES = %w[success failed].freeze

    # Pricing per unit (as of 2024)
    PRICING = {
      'openai' => {
        'whisper-1' => 0.006 # per minute
      },
      'elevenlabs' => {
        'eleven_multilingual_v2' => 0.00003, # per character
        'eleven_turbo_v2' => 0.000018 # per character
      }
    }.freeze

    validates :operation_type, inclusion: { in: OPERATION_TYPES }
    validates :provider, inclusion: { in: PROVIDERS }
    validates :status, inclusion: { in: STATUSES }

    before_save :calculate_estimated_cost, if: :should_calculate_cost?

    scope :recent, -> { where('created_at > ?', 24.hours.ago) }
    scope :transcriptions, -> { where(operation_type: 'transcription') }
    scope :synthesis, -> { where(operation_type: 'synthesis') }
    scope :successful, -> { where(status: 'success') }
    scope :failed, -> { where(status: 'failed') }
    scope :by_provider, ->(provider) { where(provider: provider) }
    scope :for_period, ->(start_date, end_date) { where(created_at: start_date..end_date) }

    class << self
      def record_transcription(account:, assistant:, duration_seconds:, model:, message: nil, success: true, error: nil)
        create!(
          account: account,
          assistant: assistant,
          message: message,
          operation_type: 'transcription',
          provider: 'openai',
          audio_duration_seconds: duration_seconds,
          model_used: model,
          status: success ? 'success' : 'failed',
          metadata: error ? { error: error } : {}
        )
      end

      def record_synthesis(account:, assistant:, characters:, voice_id:, model:, message: nil, success: true, error: nil)
        create!(
          account: account,
          assistant: assistant,
          message: message,
          operation_type: 'synthesis',
          provider: 'elevenlabs',
          characters_used: characters,
          voice_id: voice_id,
          model_used: model,
          status: success ? 'success' : 'failed',
          metadata: error ? { error: error } : {}
        )
      end

      def daily_usage(account, date = Time.current.to_date)
        for_period(date.beginning_of_day, date.end_of_day)
          .where(account: account)
          .group(:operation_type)
          .select(
            'operation_type',
            'COUNT(*) as count',
            'SUM(characters_used) as total_characters',
            'SUM(audio_duration_seconds) as total_duration',
            'SUM(estimated_cost) as total_cost'
          )
      end

      def monthly_usage(account, date = Time.current)
        for_period(date.beginning_of_month, date.end_of_month)
          .where(account: account)
          .group(:operation_type)
          .select(
            'operation_type',
            'COUNT(*) as count',
            'SUM(characters_used) as total_characters',
            'SUM(audio_duration_seconds) as total_duration',
            'SUM(estimated_cost) as total_cost'
          )
      end
    end

    private

    def should_calculate_cost?
      estimated_cost.blank? && (characters_used.positive? || audio_duration_seconds.positive?)
    end

    def calculate_estimated_cost
      self.estimated_cost = case operation_type
                            when 'transcription'
                              calculate_transcription_cost
                            when 'synthesis'
                              calculate_synthesis_cost
                            else
                              0
                            end
    end

    def calculate_transcription_cost
      return 0 unless audio_duration_seconds.positive?

      rate = PRICING.dig('openai', model_used) || PRICING.dig('openai', 'whisper-1')
      (audio_duration_seconds / 60.0) * rate
    end

    def calculate_synthesis_cost
      return 0 unless characters_used.positive?

      rate = PRICING.dig('elevenlabs', model_used) || PRICING.dig('elevenlabs', 'eleven_multilingual_v2')
      characters_used * rate
    end
  end
end
