require 'rails_helper'

RSpec.describe Captain::Llm::ConversationFaqJob, type: :job do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:assistant) { create(:captain_assistant, account: account, config: { feature_faq: true }) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, first_reply_created_at: Time.zone.now) }
  let(:faq_service) { instance_double(Captain::Llm::ConversationFaqService, generate_suggestions: []) }
  let(:lock_manager) { instance_double(Redis::LockManager, lock: true, unlock: true) }
  let(:lock_key) { "CAPTAIN_CONVERSATION_FAQ_LOCK::#{assistant.id}::en" }

  before do
    create(:captain_inbox, inbox: inbox, captain_assistant: assistant)
    conversation.update!(status: :resolved)
    allow(Redis::LockManager).to receive(:new).and_return(lock_manager)
    allow(Captain::Llm::ConversationFaqService).to receive(:new).and_return(faq_service)
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

    it 'locks FAQ grouping for the assistant and normalized language' do
      conversation.update!(additional_attributes: { conversation_language: 'pt-BR' })
      expected_key = "CAPTAIN_CONVERSATION_FAQ_LOCK::#{assistant.id}::pt"

      expect(lock_manager).to receive(:lock).with(expected_key, described_class::LOCK_TIMEOUT).and_return(true)
      expect(lock_manager).to receive(:unlock).with(expected_key)

      described_class.perform_now(conversation, assistant)
    end

    context 'when another job holds the grouping lock' do
      before do
        allow(lock_manager).to receive(:lock).with(lock_key, described_class::LOCK_TIMEOUT).and_return(false)
      end

      it 'does not generate suggestions concurrently' do
        expect(Captain::Llm::ConversationFaqService).not_to receive(:new)

        expect do
          described_class.new.perform(conversation, assistant)
        end.to raise_error(MutexApplicationJob::LockAcquisitionError)
      end
    end
  end
end
