require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'captain audience routing on create' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:us_contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'US' }) }
    let(:ca_contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'CA' }) }
    let(:assignment_enabled) { true }

    before do
      allow(GlobalConfigService).to receive(:load).and_call_original
      allow(GlobalConfigService).to receive(:load)
        .with('ENABLE_CAPTAIN_CONVERSATION_ASSIGNMENT', false)
        .and_return(assignment_enabled)
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

    context 'when Captain conversation assignment is disabled' do
      let(:assignment_enabled) { false }

      it 'does not write Captain ownership' do
        conversation = create(:conversation, account: account, inbox: inbox, contact: us_contact)

        expect(conversation.status).to eq('pending')
        expect(conversation.ai_assignee).to be_nil
      end
    end

    it 'routes an out-of-audience contact conversation to open' do
      conversation = create(:conversation, account: account, inbox: inbox, contact: ca_contact)

      expect(conversation.status).to eq('open')
      expect(conversation.ai_assignee).to be_nil
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
