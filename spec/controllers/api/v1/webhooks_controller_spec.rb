require 'rails_helper'

RSpec.describe 'Webhooks API', type: :request do
  describe 'POST /webhooks/twitter' do
    it 'drops message creation locks without reporting an exception' do
      conversation = create(:conversation)
      conversation.lock_message_creation!
      consumer = instance_double(Webhooks::Twitter)

      allow(Webhooks::Twitter).to receive(:new).and_return(consumer)
      allow(consumer).to receive(:consume).and_raise(CustomExceptions::ConversationMessageCreationLocked.new(conversation))
      expect(ChatwootExceptionTracker).not_to receive(:new)

      post '/webhooks/twitter', params: { direct_message_events: [] }

      expect(response).to have_http_status(:ok)
    end
  end
end
