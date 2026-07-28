require 'rails_helper'

RSpec.describe Voice::CallTranscriptionService, type: :service do
  let(:account) { create(:account, audio_transcriptions: true) }
  let(:conversation) { create(:conversation, account: account) }
  let(:call) { create(:call, conversation: conversation, status: 'completed') }

  before do
    allow(Llm::SpeechToTextService).to receive(:available_for?).and_return(true)
    call.recording.attach(
      io: File.open(Rails.public_path.join('audio/widget/ding.mp3')),
      filename: 'call-recording.mp3',
      content_type: 'audio/mpeg'
    )
  end

  describe '#perform' do
    it 'stores the transcript on the call' do
      allow(Llm::SpeechToTextService).to receive(:new).and_return(
        instance_double(Llm::SpeechToTextService, perform: 'Hello, how can I help?')
      )

      described_class.new(call: call).perform

      expect(call.reload.transcript).to eq('Hello, how can I help?')
    end

    it 'skips calls that are already transcribed' do
      call.update!(transcript: 'Existing transcript')

      expect(Llm::SpeechToTextService).not_to receive(:new)

      described_class.new(call: call).perform
    end

    it 'skips calls without a recording' do
      call.recording.purge

      expect(Llm::SpeechToTextService).not_to receive(:new)

      described_class.new(call: call).perform
    end

    it 'skips when transcription is unavailable for the account' do
      allow(Llm::SpeechToTextService).to receive(:available_for?).and_return(false)

      expect(Llm::SpeechToTextService).not_to receive(:new)

      described_class.new(call: call).perform
    end

    it 'leaves the transcript blank when nothing comes back' do
      allow(Llm::SpeechToTextService).to receive(:new).and_return(
        instance_double(Llm::SpeechToTextService, perform: '')
      )

      described_class.new(call: call).perform

      expect(call.reload.transcript).to be_nil
    end
  end
end
