# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::Assistant do
  subject(:assistant) { build(:aloo_assistant) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:assistant_inboxes).dependent(:destroy) }
    it { is_expected.to have_many(:inboxes).through(:assistant_inboxes) }
    it { is_expected.to have_many(:documents).dependent(:destroy) }
    it { is_expected.to have_many(:embeddings).dependent(:destroy) }
    it { is_expected.to have_many(:messages) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:tone).in_array(described_class::TONES) }
    it { is_expected.to validate_inclusion_of(:formality).in_array(described_class::FORMALITY_LEVELS) }
    it { is_expected.to validate_inclusion_of(:empathy_level).in_array(described_class::EMPATHY_LEVELS) }
    it { is_expected.to validate_inclusion_of(:verbosity).in_array(described_class::VERBOSITY_LEVELS) }
    it { is_expected.to validate_inclusion_of(:emoji_usage).in_array(described_class::EMOJI_USAGE_LEVELS) }
    it { is_expected.to validate_inclusion_of(:greeting_style).in_array(described_class::GREETING_STYLES) }
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_assistant) { create(:aloo_assistant, active: true) }
      let!(:inactive_assistant) { create(:aloo_assistant, :inactive) }

      it 'returns only active assistants' do
        expect(described_class.active).to include(active_assistant)
        expect(described_class.active).not_to include(inactive_assistant)
      end
    end
  end

  describe '#personality_prompt' do
    it 'delegates to PersonalityBuilder' do
      builder = instance_double(Aloo::PersonalityBuilder, build: 'personality prompt')
      allow(Aloo::PersonalityBuilder).to receive(:new).with(assistant).and_return(builder)

      expect(assistant.personality_prompt).to eq('personality prompt')
    end
  end

  describe '#model' do
    context 'when admin_config is empty' do
      it 'returns default model' do
        assistant.admin_config = {}
        expect(assistant.model).to eq('gpt-4.1-mini')
      end
    end

    context 'when model is configured' do
      it 'returns configured model' do
        assistant.admin_config = { 'model' => 'gpt-4o' }
        expect(assistant.model).to eq('gpt-4o')
      end
    end
  end

  describe '#temperature' do
    it 'returns default when not configured' do
      assistant.admin_config = {}
      expect(assistant.temperature).to eq(0.7)
    end

    it 'returns configured value' do
      assistant.admin_config = { 'temperature' => 0.5 }
      expect(assistant.temperature).to eq(0.5)
    end
  end

  describe '#full_system_prompt' do
    before do
      assistant.system_prompt = 'Base prompt'
      assistant.response_guidelines = 'Guidelines'
      assistant.guardrails = 'Safety rules'
    end

    it 'combines all prompt sections' do
      allow(assistant).to receive(:personality_prompt).and_return('Personality')

      result = assistant.full_system_prompt

      expect(result).to include('Base prompt')
      expect(result).to include('Personality')
      expect(result).to include('Guidelines')
      expect(result).to include('Safety rules')
    end

    it 'excludes blank sections' do
      assistant.guardrails = nil
      allow(assistant).to receive(:personality_prompt).and_return('Personality')

      result = assistant.full_system_prompt

      expect(result).not_to include('Safety rules')
    end
  end

  describe '#push_event_data' do
    let(:assistant) { create(:aloo_assistant, name: 'Test Bot') }

    it 'returns correct structure for message sender' do
      data = assistant.push_event_data

      expect(data[:id]).to eq(assistant.id)
      expect(data[:name]).to eq('Test Bot')
      expect(data[:type]).to eq('aloo_assistant')
      expect(data[:avatar_url]).to be_nil
    end
  end

  describe '#voice_transcription_enabled?' do
    it 'returns true when voice is enabled' do
      assistant.voice_enabled = true
      expect(assistant.voice_transcription_enabled?).to be true
    end

    it 'returns false when voice is disabled' do
      assistant.voice_enabled = false
      expect(assistant.voice_transcription_enabled?).to be false
    end
  end

  describe '#voice_reply_enabled?' do
    context 'when voice is disabled' do
      it 'returns false regardless of config' do
        assistant.voice_enabled = false
        assistant.voice_config = { 'tts_provider' => 'elevenlabs', 'elevenlabs_voice_id' => 'abc123' }
        expect(assistant.voice_reply_enabled?).to be false
      end
    end

    context 'when voice is enabled with ElevenLabs' do
      before { assistant.voice_enabled = true }

      it 'returns true when elevenlabs_voice_id is set' do
        assistant.voice_config = { 'tts_provider' => 'elevenlabs', 'elevenlabs_voice_id' => 'abc123' }
        expect(assistant.voice_reply_enabled?).to be true
      end

      it 'returns false when elevenlabs_voice_id is blank' do
        assistant.voice_config = { 'tts_provider' => 'elevenlabs' }
        expect(assistant.voice_reply_enabled?).to be false
      end
    end

    context 'when voice is enabled with OpenAI' do
      before { assistant.voice_enabled = true }

      it 'returns true without needing a specific voice ID' do
        assistant.voice_config = { 'tts_provider' => 'openai' }
        expect(assistant.voice_reply_enabled?).to be true
      end
    end

    context 'when voice is enabled with no tts_provider (defaults to ElevenLabs)' do
      before { assistant.voice_enabled = true }

      it 'returns true when elevenlabs_voice_id is set' do
        assistant.voice_config = { 'elevenlabs_voice_id' => 'abc123' }
        expect(assistant.voice_reply_enabled?).to be true
      end

      it 'returns false when elevenlabs_voice_id is missing' do
        assistant.voice_config = {}
        expect(assistant.voice_reply_enabled?).to be false
      end
    end
  end
end
