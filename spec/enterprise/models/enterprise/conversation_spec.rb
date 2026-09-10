require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'captain audience routing on create' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:us_contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'US' }) }
    let(:ca_contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'CA' }) }

    before do
      account.enable_features!('captain_integration')
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US']
                                                       }))
    end

    it 'parks an in-audience contact conversation as pending' do
      conversation = create(:conversation, account: account, inbox: inbox, contact: us_contact)

      expect(conversation.status).to eq('pending')
      expect(conversation.ai_assignee).to eq(assistant)
    end

    it 'routes an out-of-audience contact conversation to open' do
      conversation = create(:conversation, account: account, inbox: inbox, contact: ca_contact)

      expect(conversation.status).to eq('open')
      expect(conversation.ai_assignee).to be_nil
    end

    context 'when Captain entitlement is disabled but credits remain' do
      before do
        account.disable_features!('captain_integration')
        allow(account).to receive(:usage_limits).and_return(captain: { responses: { current_available: 10 } })
      end

      it 'keeps a new conversation open without Captain ownership' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: us_contact)

        expect(inbox.captain_active?).to be(false)
        expect(conversation).to have_attributes(status: 'open', ai_assignee: nil)
      end

      it 'does not assign Captain to an explicitly pending conversation' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: us_contact, status: :pending)

        expect(conversation).to have_attributes(status: 'pending', ai_assignee: nil)
      end
    end

    it 'notifies assignment changes when only the AI owner type changes' do
      agent_bot = create(:agent_bot, id: assistant.id, account: account)
      conversation = create(:conversation, account: account, inbox: inbox, contact: us_contact)
      conversation.update!(ai_assignee: agent_bot)
      allow(Rails.configuration.dispatcher).to receive(:dispatch)

      conversation.update!(ai_assignee: assistant)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(Conversation::ASSIGNEE_CHANGED, kind_of(Time), hash_including(
                                                               conversation: conversation,
                                                               changed_attributes: conversation.previous_changes
                                                             ))
    end
  end
end
