require 'rails_helper'

describe Digitaltolk::AddMessageService do
  subject { described_class.new(sender, conversation, content) }

  let(:sender) { create(:user, message_signature: 'message signature test') }
  let(:conversation) { create(:conversation) }
  let(:content) { 'Hello, this is a test message.' }

  describe '#perform' do
    it 'creates a message' do
      result = subject.perform
      expect(result).to be_a(Message)
      expect(result.content).to eq("Hello, this is a test message.\n\n\n\nmessage signature test")
    end

    shared_examples 'not creating a message' do
      it 'does not create a message' do
        expect(Messages::MessageBuilder).not_to receive(:new)
        expect(subject.perform).to be_nil
      end

      it 'does not trigger an error' do
        expect { subject.perform }.not_to raise_error
      end

      it 'does not call the job to format the email' do
        expect(Digitaltolk::FormatOutgoingEmailJob).not_to receive(:perform_later)
        subject.perform
      end
    end

    context 'when conversation is blank' do
      let(:conversation) { nil }

      it_behaves_like 'not creating a message'
    end

    context 'when content is blank' do
      let(:content) { nil }

      it_behaves_like 'not creating a message'
    end

    it 'calls the job to format the email' do
      expect(Digitaltolk::FormatOutgoingEmailJob).to receive(:perform_later).once
      subject.perform
    end

    it 'attach the message signature' do
      message = subject.perform
      expect(message.content).to include(sender.message_signature)
    end
  end
end
