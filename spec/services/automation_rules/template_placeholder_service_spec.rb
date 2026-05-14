require 'rails_helper'

RSpec.describe AutomationRules::TemplatePlaceholderService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, name: 'Alice Agent', email: 'alice@example.com') }
  let(:contact) { create(:contact, account: account, name: 'Bob Buyer', email: 'bob@example.com', phone_number: '+15551234567') }
  let(:inbox) { create(:inbox, account: account, name: 'Support Email') }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact, assignee: agent) }

  subject(:service) { described_class.new(conversation) }

  describe '#substitute' do
    it 'resolves contact tokens via Liquid drops' do
      expect(service.substitute('Hi {{contact.name}}, email {{contact.email}}')).to eq('Hi Bob Buyer, email bob@example.com')
    end

    it 'resolves inbox tokens (handy when the trigger inbox name is descriptive)' do
      expect(service.substitute('Thanks for emailing {{inbox.name}}')).to eq('Thanks for emailing Support Email')
    end

    it 'resolves conversation tokens' do
      expect(service.substitute('Ref #{{conversation.display_id}}')).to eq("Ref ##{conversation.display_id}")
    end

    it 'resolves agent tokens when an assignee exists' do
      expect(service.substitute('Reply to {{agent.name}}')).to eq("Reply to #{agent.available_name}")
    end

    it 'leaves agent tokens empty when there is no assignee' do
      conversation.update!(assignee: nil)
      svc = described_class.new(conversation.reload)
      expect(svc.substitute('Reply to {{agent.name}}')).to eq('Reply to ')
    end

    it 'passes through values that contain no liquid markers' do
      expect(service.substitute('Tomorrow at 3pm')).to eq('Tomorrow at 3pm')
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
