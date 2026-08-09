require 'rails_helper'

RSpec.describe Conversation, type: :model do
  describe 'captain audience routing on create' do
    let(:account) { create(:account) }
    let(:inbox) { create(:inbox, account: account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:us_contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'US' }) }
    let(:ca_contact) { create(:contact, account: account, additional_attributes: { 'country_code' => 'CA' }) }

    before do
      create(:captain_inbox, captain_assistant: assistant, inbox: inbox)
      assistant.update!(config: assistant.config.merge('audience' => {
                                                         'attribute_key' => 'country_code', 'filter_operator' => 'equal_to', 'values' => ['US']
                                                       }))
    end

    it 'parks an in-audience contact conversation as pending' do
      conversation = create(:conversation, account: account, inbox: inbox, contact: us_contact)
      expect(conversation.status).to eq('pending')
    end

    it 'routes an out-of-audience contact conversation to open' do
      conversation = create(:conversation, account: account, inbox: inbox, contact: ca_contact)
      expect(conversation.status).to eq('open')
    end
  end
end
