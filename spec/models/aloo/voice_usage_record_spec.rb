# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::VoiceUsageRecord do
  subject(:record) { build(:aloo_voice_usage_record) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant') }
    it { is_expected.to belong_to(:message).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_inclusion_of(:operation_type).in_array(described_class::OPERATION_TYPES) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(described_class::PROVIDERS) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe 'scopes' do
    let!(:transcription_record) { create(:aloo_voice_usage_record, :transcription) }
    let!(:synthesis_record) { create(:aloo_voice_usage_record, :synthesis) }
    let!(:failed_record) { create(:aloo_voice_usage_record, :failed) }
    let!(:old_record) { create(:aloo_voice_usage_record, created_at: 2.days.ago) }

    describe '.transcriptions' do
      it 'returns only transcription records' do
        expect(described_class.transcriptions).to include(transcription_record)
        expect(described_class.transcriptions).not_to include(synthesis_record)
      end
    end

    describe '.synthesis' do
      it 'returns only synthesis records' do
        expect(described_class.synthesis).to include(synthesis_record)
        expect(described_class.synthesis).not_to include(transcription_record)
      end
    end

    describe '.successful' do
      it 'returns only successful records' do
        expect(described_class.successful).to include(transcription_record, synthesis_record)
        expect(described_class.successful).not_to include(failed_record)
      end
    end

    describe '.failed' do
      it 'returns only failed records' do
        expect(described_class.failed).to include(failed_record)
        expect(described_class.failed).not_to include(transcription_record)
      end
    end

    describe '.recent' do
      it 'returns records from last 24 hours' do
        expect(described_class.recent).to include(transcription_record)
        expect(described_class.recent).not_to include(old_record)
      end
    end

    describe '.for_period' do
      it 'returns records within the specified period' do
        start_date = 1.day.ago
        end_date = Time.current

        expect(described_class.for_period(start_date, end_date)).to include(transcription_record)
        expect(described_class.for_period(start_date, end_date)).not_to include(old_record)
      end
    end
  end

  describe '.record_transcription' do
    let(:account) { create(:account) }
    let(:assistant) { create(:aloo_assistant, account: account) }

    it 'creates a transcription record' do
      expect do
        described_class.record_transcription(
          account: account,
          assistant: assistant,
          duration_seconds: 60,
          model: 'whisper-1'
        )
      end.to change(described_class, :count).by(1)
    end

    it 'sets correct attributes' do
      record = described_class.record_transcription(
        account: account,
        assistant: assistant,
        duration_seconds: 60,
        model: 'whisper-1'
      )

      expect(record.operation_type).to eq('transcription')
      expect(record.provider).to eq('openai')
      expect(record.audio_duration_seconds).to eq(60)
      expect(record.model_used).to eq('whisper-1')
      expect(record.status).to eq('success')
    end

    it 'records failed transcription' do
      record = described_class.record_transcription(
        account: account,
        assistant: assistant,
        duration_seconds: 0,
        model: 'whisper-1',
        success: false,
        error: 'API error'
      )

      expect(record.status).to eq('failed')
      expect(record.metadata['error']).to eq('API error')
    end
  end

  describe '.record_synthesis' do
    let(:account) { create(:account) }
    let(:assistant) { create(:aloo_assistant, account: account) }

    it 'creates a synthesis record' do
      expect do
        described_class.record_synthesis(
          account: account,
          assistant: assistant,
          characters: 200,
          voice_id: 'test-voice',
          model: 'eleven_multilingual_v2'
        )
      end.to change(described_class, :count).by(1)
    end

    it 'sets correct attributes' do
      record = described_class.record_synthesis(
        account: account,
        assistant: assistant,
        characters: 200,
        voice_id: 'test-voice',
        model: 'eleven_multilingual_v2'
      )

      expect(record.operation_type).to eq('synthesis')
      expect(record.provider).to eq('elevenlabs')
      expect(record.characters_used).to eq(200)
      expect(record.voice_id).to eq('test-voice')
      expect(record.model_used).to eq('eleven_multilingual_v2')
    end
  end

  describe 'cost calculation' do
    context 'for transcription' do
      it 'calculates cost based on duration' do
        record = create(:aloo_voice_usage_record, :transcription, audio_duration_seconds: 120)

        # 120 seconds = 2 minutes, at $0.006/minute = $0.012
        expect(record.estimated_cost).to be_within(0.0001).of(0.012)
      end
    end

    context 'for synthesis' do
      it 'calculates cost based on characters' do
        record = create(:aloo_voice_usage_record, :synthesis, characters_used: 1000)

        # 1000 chars at $0.00003/char = $0.03
        expect(record.estimated_cost).to be_within(0.0001).of(0.03)
      end
    end
  end

  describe '.daily_usage' do
    let(:account) { create(:account) }
    let(:assistant) { create(:aloo_assistant, account: account) }

    before do
      create(:aloo_voice_usage_record, :transcription, account: account, assistant: assistant)
      create(:aloo_voice_usage_record, :transcription, account: account, assistant: assistant)
      create(:aloo_voice_usage_record, :synthesis, account: account, assistant: assistant)
    end

    it 'returns usage grouped by operation type' do
      usage = described_class.daily_usage(account)

      transcription_usage = usage.find { |u| u.operation_type == 'transcription' }
      synthesis_usage = usage.find { |u| u.operation_type == 'synthesis' }

      expect(transcription_usage.count).to eq(2)
      expect(synthesis_usage.count).to eq(1)
    end
  end

  describe '.monthly_usage' do
    let(:account) { create(:account) }
    let(:assistant) { create(:aloo_assistant, account: account) }

    before do
      create_list(:aloo_voice_usage_record, 3, :transcription, account: account, assistant: assistant)
      create_list(:aloo_voice_usage_record, 2, :synthesis, account: account, assistant: assistant)
    end

    it 'returns monthly usage totals' do
      usage = described_class.monthly_usage(account)

      transcription_usage = usage.find { |u| u.operation_type == 'transcription' }

      expect(transcription_usage.count).to eq(3)
    end
  end
end
