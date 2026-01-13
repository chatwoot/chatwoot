require 'rails_helper'

RSpec.describe Captain::BaseTaskService, type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  # Create a concrete test service class
  let(:test_service_class) do
    Class.new(described_class) do
      def perform
        { message: 'Test response' }
      end

      def event_name
        'test_event'
      end
    end
  end

  let(:service) { test_service_class.new(account: account, conversation_display_id: conversation.display_id) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
  end

  describe '#perform with enterprise usage tracking' do
    it 'increments response usage on successful execution' do
      expect(account).to receive(:increment_response_usage)
      service.perform
    end

    it 'does not increment usage when result has an error' do
      allow(service).to receive(:execute_task).and_return({ error: 'API Error' })
      expect(account).not_to receive(:increment_response_usage)
      service.perform
    end

    it 'does not increment usage when result is nil' do
      allow(service).to receive(:execute_task).and_return(nil)
      expect(account).not_to receive(:increment_response_usage)
      service.perform
    end

    it 'does not increment usage when result is empty hash' do
      allow(service).to receive(:execute_task).and_return({})
      expect(account).not_to receive(:increment_response_usage)
      service.perform
    end

    it 'does not increment usage when result has blank message' do
      allow(service).to receive(:execute_task).and_return({ message: '' })
      expect(account).not_to receive(:increment_response_usage)
      service.perform
    end

    it 'does not increment usage when result has nil message' do
      allow(service).to receive(:execute_task).and_return({ message: nil })
      expect(account).not_to receive(:increment_response_usage)
      service.perform
    end

    it 'actually increments the usage counter in custom_attributes' do
      expect do
        service.perform
        account.reload
      end.to change { account.custom_attributes['captain_responses_usage'].to_i }.by(1)
    end
  end
end
