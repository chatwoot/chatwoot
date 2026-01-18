# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_voice_usage_record, class: 'Aloo::VoiceUsageRecord' do
    account
    association :assistant, factory: :aloo_assistant
    operation_type { 'transcription' }
    provider { 'openai' }
    status { 'success' }
    audio_duration_seconds { 30 }
    model_used { 'whisper-1' }
    metadata { {} }

    trait :transcription do
      operation_type { 'transcription' }
      provider { 'openai' }
      audio_duration_seconds { rand(5..120) }
      model_used { 'whisper-1' }
    end

    trait :synthesis do
      operation_type { 'synthesis' }
      provider { 'elevenlabs' }
      characters_used { rand(50..500) }
      voice_id { 'EXAVITQu4vr4xnSDxMaL' }
      model_used { 'eleven_multilingual_v2' }
      audio_duration_seconds { 0 }
    end

    trait :failed do
      status { 'failed' }
      metadata { { 'error' => 'API error' } }
    end

    trait :with_message do
      message
    end
  end
end
