require 'rails_helper'

RSpec.describe Captain::BaseTaskService, type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:perform_result) { { message: 'Test response' } }

  # Create a concrete test service class with enterprise module prepended
  let(:test_service_class) do
    result = perform_result
    klass = Class.new(described_class) do
      define_method(:perform) { result }

      def event_name
        'test_event'
      end
    end
    # Manually prepend enterprise module to test class
    klass.prepend(Enterprise::Captain::BaseTaskService)
    klass
  end

  let(:service) { test_service_class.new(account: account, conversation_display_id: conversation.display_id) }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
  end

  describe '#perform with enterprise usage tracking' do
    # Ensure captain is enabled by default for tests unless explicitly testing disabled state
    before do
      allow(account).to receive(:feature_enabled?).and_call_original
      allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
    end

    context 'when usage limit is exceeded' do
      before do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        allow(account).to receive(:usage_limits).and_return({
                                                              captain: { responses: { current_available: 0 } }
                                                            })
      end

      it 'returns usage limit exceeded error' do
        result = service.perform
        expect(result[:error]).to eq(I18n.t('captain.copilot_limit'))
        expect(result[:error_code]).to eq(429)
      end

      it 'does not increment usage' do
        expect(account).not_to receive(:increment_response_usage)
        service.perform
      end
    end

    it 'increments response usage on successful execution' do
      expect(account).to receive(:increment_response_usage)
      service.perform
    end

    context 'when result has an error' do
      let(:perform_result) { { error: 'API Error' } }

      it 'does not increment usage' do
        expect(account).not_to receive(:increment_response_usage)
        service.perform
      end
    end

    context 'when result is nil' do
      let(:perform_result) { nil }

      it 'does not increment usage' do
        expect(account).not_to receive(:increment_response_usage)
        service.perform
      end
    end

    context 'when result is empty hash' do
      let(:perform_result) { {} }

      it 'does not increment usage' do
        expect(account).not_to receive(:increment_response_usage)
        service.perform
      end
    end

    context 'when result has blank message' do
      let(:perform_result) { { message: '' } }

      it 'does not increment usage' do
        expect(account).not_to receive(:increment_response_usage)
        service.perform
      end
    end

    context 'when result has nil message' do
      let(:perform_result) { { message: nil } }

      it 'does not increment usage' do
        expect(account).not_to receive(:increment_response_usage)
        service.perform
      end
    end

    it 'actually increments the usage counter in custom_attributes' do
      expect do
        service.perform
        account.reload
      end.to change { account.custom_attributes['captain_responses_usage'].to_i }.by(1)
    end

    context 'when captain is disabled' do
      before do
        allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(false)
      end

      context 'when on Chatwoot Cloud' do
        before do
          allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
        end

        it 'returns upgrade error message' do
          result = service.perform
          expect(result[:error]).to eq(I18n.t('captain.upgrade'))
        end

        it 'does not increment usage' do
          expect(account).not_to receive(:increment_response_usage)
          service.perform
        end
      end

      context 'when self-hosted' do
        before do
          allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
        end

        it 'returns disabled error message' do
          result = service.perform
          expect(result[:error]).to eq(I18n.t('captain.disabled'))
        end

        it 'does not increment usage' do
          expect(account).not_to receive(:increment_response_usage)
          service.perform
        end
      end
    end

    context 'when captain is enabled' do
      before do
        allow(account).to receive(:feature_enabled?).with('captain_tasks').and_return(true)
      end

      it 'proceeds with the task' do
        result = service.perform
        expect(result[:message]).to eq('Test response')
        expect(result[:error]).to be_nil
      end

      it 'increments usage' do
        expect(account).to receive(:increment_response_usage)
        service.perform
      end
    end
  end
end
