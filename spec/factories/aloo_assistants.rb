# frozen_string_literal: true

FactoryBot.define do
  factory :aloo_assistant, class: 'Aloo::Assistant' do
    account
    name { Faker::Name.name }
    description { Faker::Lorem.sentence }
    tone { 'friendly' }
    formality { 'medium' }
    empathy_level { 'medium' }
    verbosity { 'balanced' }
    emoji_usage { 'minimal' }
    greeting_style { 'warm' }
    language { 'en' }
    active { true }
    system_prompt { 'You are a helpful customer support assistant.' }
    admin_config { {} }

    trait :inactive do
      active { false }
    end

    trait :arabic do
      language { 'ar' }
      dialect { 'EG' }
    end

    trait :professional do
      tone { 'professional' }
      formality { 'high' }
    end

    trait :with_memory_enabled do
      admin_config { { 'feature_memory' => true } }
    end

    trait :with_all_features do
      admin_config { { 'feature_memory' => true } }
    end

    trait :with_custom_model do
      admin_config { { 'model' => 'gpt-4o', 'temperature' => 0.5 } }
    end

    trait :with_voice_input do
      voice_enabled { true }
      voice_config { { 'transcription_provider' => 'openai', 'transcription_model' => 'whisper-1' } }
    end

    trait :with_voice_output do
      voice_enabled { true }
      voice_config do
        {
          'tts_provider' => 'elevenlabs',
          'elevenlabs_voice_id' => 'EXAVITQu4vr4xnSDxMaL',
          'elevenlabs_model_id' => 'eleven_multilingual_v2',
          'elevenlabs_stability' => 0.5,
          'elevenlabs_similarity_boost' => 0.75,
          'reply_mode' => 'text_and_voice'
        }
      end
    end

    trait :with_voice_features do
      voice_enabled { true }
      voice_config do
        {
          'transcription_provider' => 'openai',
          'transcription_model' => 'whisper-1',
          'tts_provider' => 'elevenlabs',
          'elevenlabs_voice_id' => 'EXAVITQu4vr4xnSDxMaL',
          'elevenlabs_model_id' => 'eleven_multilingual_v2',
          'elevenlabs_stability' => 0.5,
          'elevenlabs_similarity_boost' => 0.75,
          'reply_mode' => 'text_and_voice'
        }
      end
    end
  end
end
