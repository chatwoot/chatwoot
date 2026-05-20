require 'rails_helper'

RSpec.describe Integrations::SocialwiseFlow::ProcessorService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:hook) do
    create(
      :integrations_hook,
      inbox: inbox,
      account: account,
      app_id: 'socialwise_flow',
      settings: { 'language' => 'pt-BR' }
    )
  end
  let(:conversation) { create(:conversation, account: account, inbox: inbox, status: :open) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }
  let(:service) { described_class.new(event_name: 'message.created', hook: hook, event_data: { message: message }) }

  describe '#bot_should_respond?' do
    it 'allows open conversations with an old human reply when no explicit handoff exists' do
      allow(service).to receive(:has_agent_reply?).and_return(true)
      allow(service).to receive(:handoff_completed?).and_return(false)

      expect(service.send(:bot_should_respond?)).to be(true)
    end

    it 'blocks open conversations after explicit Socialwise handoff' do
      allow(service).to receive(:has_agent_reply?).and_return(false)
      allow(service).to receive(:handoff_completed?).and_return(true)

      expect(service.send(:bot_should_respond?)).to be(false)
    end

    it 'sees handoff flags written after the conversation was memoized' do
      service.send(:conversation)
      Conversation.find(conversation.id).update!(
        additional_attributes: {
          'socialwise_handoff_at' => Time.current.iso8601,
          'socialwise_handoff_by' => 'bot'
        }
      )

      expect(service.send(:handoff_completed?)).to be(true)
    end
  end

  describe '#process_response' do
    it 'does not send a late bot response after handoff was completed by another job' do
      service.send(:conversation)
      Conversation.find(conversation.id).update!(
        additional_attributes: {
          'socialwise_handoff_at' => Time.current.iso8601,
          'socialwise_handoff_by' => 'bot'
        }
      )

      expect(service).not_to receive(:create_conversation)

      service.send(:process_response, message, { 'text' => 'late bot reply' })
    end
  end

  describe '#should_run_processor?' do
    it 'marks handoff when a human agent sends an outgoing reply' do
      agent_reply = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        message_type: :outgoing,
        sender: create(:user, account: account)
      )

      expect(service.send(:should_run_processor?, agent_reply)).to be_nil
      expect(conversation.reload.additional_attributes['socialwise_handoff_at']).to be_present
      expect(conversation.additional_attributes['socialwise_handoff_by']).to eq('agent_reply')
    end

    it 'does not mark handoff again for outgoing message updates' do
      updated_service = described_class.new(event_name: 'message.updated', hook: hook, event_data: { message: message })
      agent_reply = create(
        :message,
        account: account,
        inbox: inbox,
        conversation: conversation,
        message_type: :outgoing,
        sender: create(:user, account: account)
      )

      expect(updated_service.send(:should_run_processor?, agent_reply)).to be_nil
      expect(conversation.reload.additional_attributes['socialwise_handoff_at']).to be_nil
    end
  end
end
