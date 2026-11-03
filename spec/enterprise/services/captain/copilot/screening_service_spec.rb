require 'rails_helper'

RSpec.describe Captain::Copilot::ScreeningService do
  let(:account) { instance_double(Account) }
  let(:run) { instance_double(CopilotRun::Review, account_id: 1, account: account, question: 'Is this about billing?') }
  let(:client) { instance_double(Captain::JevClient) }
  let(:conversation) { instance_double(Conversation) }
  let(:service) { described_class.new(run, 'lease-token') }

  before do
    allow(Captain::JevClient).to receive(:new).and_return(client)
    allow(service).to receive(:transcript).with(conversation).and_return([{ sender: 'customer', text: 'Billing help' }])
  end

  describe '#score' do
    it 'records Jev cost on the Copilot turn' do
      allow(client).to receive(:call).and_return(
        { 'answers' => { 'match' => { 'noul' => 0.9 } }, 'usage' => { 'cost' => 0.000001 } }
      )

      expect(run).to receive(:record_cost!).with(0.000001)

      expect(service.send(:score, conversation)).to eq(0.9)
    end

    it 'keeps the score and marks cost incomplete when Jev omits cost' do
      allow(client).to receive(:call).and_return({ 'answers' => { 'match' => { 'noul' => 0.9 } } })

      expect(run).to receive(:record_cost!).with(nil)

      expect(service.send(:score, conversation)).to eq(0.9)
    end
  end
end
