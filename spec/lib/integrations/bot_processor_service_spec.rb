require 'rails_helper'

RSpec.describe Integrations::BotProcessorService do
  describe '#perform' do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, account: conversation.account, inbox: conversation.inbox) }
    let(:service) { described_class.new(event_name: 'message.created', hook: nil, event_data: { message: message }) }

    it 'drops locked bot responses without reporting an exception' do
      allow(service).to receive(:should_run_processor?).and_return(true)
      allow(service).to receive(:process_content).and_raise(CustomExceptions::ConversationMessageCreationLocked.new(conversation))
      expect(ChatwootExceptionTracker).not_to receive(:new)

      expect { service.perform }.not_to raise_error
    end
  end
end
