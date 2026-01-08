# frozen_string_literal: true

class AddVoiceSettingsToAlooAssistants < ActiveRecord::Migration[7.0]
  def change
    add_column :aloo_assistants, :voice_enabled, :boolean, default: false
    add_column :aloo_assistants, :voice_input_enabled, :boolean, default: false
    add_column :aloo_assistants, :voice_output_enabled, :boolean, default: false
    add_column :aloo_assistants, :voice_config, :jsonb, default: {}

    # voice_config schema:
    # {
    #   "transcription_provider": "openai",  # openai only for now
    #   "transcription_model": "whisper-1",
    #   "tts_provider": "elevenlabs",
    #   "elevenlabs_voice_id": "xxx",
    #   "elevenlabs_model_id": "eleven_multilingual_v2",
    #   "elevenlabs_stability": 0.5,
    #   "elevenlabs_similarity_boost": 0.75,
    #   "reply_mode": "text_and_voice"  # text_only, voice_only, text_and_voice
    # }

    add_index :aloo_assistants, :voice_enabled
    add_index :aloo_assistants, :voice_input_enabled
    add_index :aloo_assistants, :voice_output_enabled
  end
end
