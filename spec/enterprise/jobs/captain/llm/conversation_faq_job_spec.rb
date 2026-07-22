require 'rails_helper'

RSpec.describe Captain::Llm::ConversationFaqJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account, config: { feature_faq: true }) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, first_reply_created_at: Time.zone.now) }
  let(:faq_service) { instance_double(Captain::Llm::ConversationFaqService, generate_suggestions: []) }

  before do
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)
    conversation.update!(status: :resolved)
  end

  describe '#perform' do
    it 'uses the assistant captured when the job was enqueued' do
      replacement_assistant = create(:captain_assistant, account: account, config: { feature_faq: true })
      inbox.captain_inbox.update!(captain_assistant: replacement_assistant)

      expect(inbox.reload.captain_assistant).to eq(replacement_assistant)
      expect(Captain::Llm::ConversationFaqService).to receive(:new)
        .with(assistant, conversation)
        .and_return(faq_service)
      expect(faq_service).to receive(:generate_suggestions)

      described_class.perform_now(conversation, assistant)
    end
  end
end
