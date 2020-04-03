require 'rails_helper'

describe ::MessageTemplates::HookExecutionService do
  context 'when it is a first message from web widget' do
    it 'calls ::MessageTemplates::Template::EmailCollect' do
      contact = create(:contact, email: nil)
      conversation = create(:conversation, contact: contact)
      message = create(:message, conversation: conversation)

      # this hook will only get executed for conversations with out any template messages
      message.conversation.messages.template.destroy_all

      email_collect_service = double
      allow(::MessageTemplates::Template::EmailCollect).to receive(:new).and_return(email_collect_service)
      allow(email_collect_service).to receive(:perform).and_return(true)

      described_class.new(message: message).perform

      expect(::MessageTemplates::Template::EmailCollect).to have_received(:new).with(conversation: message.conversation)
      expect(email_collect_service).to have_received(:perform)
    end
  end
end
