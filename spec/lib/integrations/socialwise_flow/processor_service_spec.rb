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
  let(:instagram_payload_without_format) do
    {
      'text' => 'Olá! Sou a Ana e posso ajudar. Escolha uma opção:',
      'quick_replies' => [
        { 'content_type' => 'text', 'title' => 'Mandado OAB', 'payload' => '@mandado-de-seguranca-oab' }
      ]
    }
  end

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

    context 'with Instagram quick replies without message_format' do
      let(:instagram_channel) { create(:channel_instagram, account: account) }
      let(:instagram_inbox) { instagram_channel.inbox }
      let(:instagram_hook) do
        create(
          :integrations_hook,
          inbox: instagram_inbox,
          account: account,
          app_id: 'socialwise_flow',
          settings: { 'language' => 'pt-BR' }
        )
      end
      let(:instagram_conversation) { create(:conversation, account: account, inbox: instagram_inbox, status: :open) }
      let(:instagram_message) do
        create(:message, account: account, inbox: instagram_inbox, conversation: instagram_conversation)
      end
      let(:instagram_service) do
        described_class.new(event_name: 'message.created', hook: instagram_hook, event_data: { message: instagram_message })
      end

      it 'infers QUICK_REPLIES and sends the rich payload to the Instagram processor' do
        expect(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).with(
          {
            'message_format' => 'QUICK_REPLIES',
            'payload' => instagram_payload_without_format
          },
          instagram_message
        ).and_return(true)

        expect(instagram_service).not_to receive(:create_fallback_instagram_message)

        instagram_service.send(:process_response, instagram_message, { 'instagram' => instagram_payload_without_format })
      end
    end
  end

  describe '#create_fallback_instagram_message' do
    it 'uses the payload text instead of sending the internal placeholder' do
      expect(service).to receive(:create_conversation).with(
        message,
        { content: 'Olá! Sou a Ana e posso ajudar. Escolha uma opção:' }
      )

      service.send(:create_fallback_instagram_message, message, instagram_payload_without_format)
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
