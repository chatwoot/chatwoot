require 'rails_helper'

RSpec.describe AutomationRules::TemplatePlaceholderService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, name: 'Alice Agent', email: 'alice@example.com') }
  let(:contact) { create(:contact, account: account, name: 'Bob Buyer', email: 'bob@example.com', phone_number: '+15551234567') }
  let(:conversation) { create(:conversation, account: account, contact: contact, assignee: agent) }

  subject(:service) { described_class.new(conversation) }

  describe '#substitute' do
    it 'resolves contact tokens' do
      expect(service.substitute('Hi {{contact.name}}, email {{contact.email}}')).to eq('Hi Bob Buyer, email bob@example.com')
    end

    it 'resolves conversation tokens' do
      expect(service.substitute('Ref #{{conversation.display_id}}')).to eq("Ref ##{conversation.display_id}")
    end

    it 'resolves agent tokens' do
      expect(service.substitute('Reply to {{agent.name}}')).to eq('Reply to Alice Agent')
    end

    it 'leaves unrecognised tokens empty rather than literal placeholders' do
      expect(service.substitute('Code: {{contact.unknown}}!')).to eq('Code: !')
    end

    it 'is whitespace-tolerant inside the token' do
      expect(service.substitute('Hi {{ contact.name }}')).to eq('Hi Bob Buyer')
    end

    it 'returns non-string values unchanged' do
      expect(service.substitute(nil)).to be_nil
      expect(service.substitute(42)).to eq(42)
    end
  end

  describe '#substitute_processed_params' do
    it 'transforms every value in the hash' do
      result = service.substitute_processed_params('1' => '{{contact.name}}', '2' => 'literal')
      expect(result).to eq('1' => 'Bob Buyer', '2' => 'literal')
    end

    it 'returns an empty hash for blank input' do
      expect(service.substitute_processed_params(nil)).to eq({})
      expect(service.substitute_processed_params({})).to eq({})
    end
  end
end
