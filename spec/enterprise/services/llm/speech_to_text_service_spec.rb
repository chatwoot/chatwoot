require 'rails_helper'

RSpec.describe Llm::SpeechToTextService, type: :service do
  let(:account) { create(:account, audio_transcriptions: true) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation) }
  let(:attachment) { message.attachments.create!(account: account, file_type: :audio) }
  let(:service) { described_class.new(blob: attachment.file.blob, account: account) }

  before do
    InstallationConfig.find_or_create_by!(name: 'CAPTAIN_OPEN_AI_API_KEY') { |config| config.value = 'test-api-key' }
    InstallationConfig.find_or_create_by!(name: 'CAPTAIN_OPEN_AI_MODEL') { |config| config.value = 'gpt-4o-mini' }

    attachment.file.attach(
      io: File.open(Rails.public_path.join('audio/widget/ding.mp3')),
      filename: 'speech',
      content_type: 'audio/mpeg'
    )
  end

  describe '.available_for?' do
    before do
      allow(account).to receive(:usage_limits).and_return(
        {
          agents: ChatwootApp.max_limit,
          inboxes: ChatwootApp.max_limit,
          captain: { responses: { current_available: 100 } }
        }
      )
    end

    it 'is false when the captain_integration feature is disabled' do
      account.disable_features!('captain_integration')

      expect(described_class.available_for?(account)).to be(false)
    end

    it 'is false when audio transcriptions are disabled on the account' do
      account.enable_features!('captain_integration')
      account.update!(audio_transcriptions: false)

      expect(described_class.available_for?(account)).to be(false)
    end

    it 'is false when no captain responses are available' do
      account.enable_features!('captain_integration')
      allow(account).to receive(:usage_limits).and_return(captain: { responses: { current_available: 0 } })

      expect(described_class.available_for?(account)).to be(false)
    end

    it 'is true when the feature, setting and credits are all present' do
      account.enable_features!('captain_integration')

      expect(described_class.available_for?(account)).to be(true)
    end
  end

  describe '.too_large?' do
    it 'is false when the blob is missing' do
      expect(described_class.too_large?(nil)).to be(false)
    end

    it 'is true beyond the byte limit' do
      allow(attachment.file.blob).to receive(:byte_size).and_return(described_class::BYTE_LIMIT + 1)

      expect(described_class.too_large?(attachment.file.blob)).to be(true)
    end
  end

  describe '#fetch_audio_file' do
    it 'adds extension from content type when filename has no extension' do
      temp_file_path = service.send(:fetch_audio_file)

      expect(File.extname(temp_file_path)).to eq('.mpeg')
    ensure
      FileUtils.rm_f(temp_file_path) if temp_file_path.present?
    end
  end

  describe '#perform' do
    let(:audio_api) { double('audio_api') } # rubocop:disable RSpec/VerifiedDoubles
    let(:audio_file_path) { Rails.root.join('tmp/speech_to_text_service_spec.mp3').to_s }

    before do
      File.binwrite(audio_file_path, 'audio')
      allow(service).to receive(:fetch_audio_file).and_return(audio_file_path)
      allow(account).to receive(:increment_response_usage)
      allow(service.client).to receive(:audio).and_return(audio_api)
    end

    after do
      FileUtils.rm_f(audio_file_path)
    end

    it 'uses the audio transcription feature model' do
      expect(audio_api).to receive(:transcribe).with(
        parameters: hash_including(model: 'gpt-4o-mini-transcribe', temperature: 0.0)
      ).and_return({ 'text' => 'Audio transcript' })

      expect(service.perform).to eq('Audio transcript')
    end

    it 'consumes a captain response credit when text comes back' do
      allow(audio_api).to receive(:transcribe).and_return({ 'text' => 'Audio transcript' })

      service.perform

      expect(account).to have_received(:increment_response_usage)
    end

    it 'does not consume a credit when the transcription is blank' do
      allow(audio_api).to receive(:transcribe).and_return({ 'text' => '' })

      service.perform

      expect(account).not_to have_received(:increment_response_usage)
    end
  end
end
