require 'rails_helper'

RSpec.describe Voice::CallTranscriptionService, type: :service do
  let(:account) { create(:account, audio_transcriptions: true) }
  let(:channel) { create(:channel_twilio_sms, :with_voice, account: account, phone_number: '+15551238888') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, content_type: :voice_call) }
  let(:call) do
    create(:call, account: account, inbox: inbox, conversation: conversation, contact: conversation.contact, status: 'completed', message: message)
  end

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

    it 'reindexes before broadcasting so a retry after a reindex failure does not resend the update event' do
      call.update!(transcript: 'Existing transcript')
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(true)
      allow(message).to receive(:reindex).and_raise(StandardError, 'reindex boom')

      expect(message).not_to receive(:send_update_event)
      expect { described_class.new(call: call).perform }.to raise_error(StandardError, 'reindex boom')
    end
  end
end
