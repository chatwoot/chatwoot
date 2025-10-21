require 'rails_helper'

RSpec.describe Crm::SetupJob do
  subject(:job) { described_class.perform_later(hook.id) }

  let(:account) { create(:account) }
  let(:hook) do
    create(:integrations_hook,
           account: account,
           app_id: 'leadsquared',
           settings: {
             access_key: 'test_key',
             secret_key: 'test_token',
             endpoint_url: 'https://api.leadsquared.com'
           })
  end

  before do
    account.enable_features('crm_integration')
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(hook.id)
      .on_queue('default')
  end

  describe '#perform' do
    context 'when hook is not found' do
      it 'returns without processing' do
        allow(Integrations::Hook).to receive(:find_by).and_return(nil)
        expect(described_class.new.perform(0)).to be_nil
      end
    end

    context 'when hook is disabled' do
      it 'returns without processing' do
        disabled_hook = create(:integrations_hook,
                               account: account,
                               app_id: 'leadsquared',
                               status: 'disabled',
                               settings: {
                                 access_key: 'test_key',
                                 secret_key: 'test_token',
                                 endpoint_url: 'https://api.leadsquared.com'
                               })
        expect(described_class.new.perform(disabled_hook.id)).to be_nil
      end
    end

    context 'when hook is not a CRM integration' do
      it 'returns without processing' do
        non_crm_hook = create(:integrations_hook,
                              account: account,
                              app_id: 'slack',
                              settings: { webhook_url: 'https://slack.com/webhook' })
        expect(described_class.new.perform(non_crm_hook.id)).to be_nil
      end
    end

    context 'when hook is valid' do
      let(:setup_service) { instance_double(Crm::Leadsquared::SetupService) }

      before do
        allow(Crm::Leadsquared::SetupService).to receive(:new).with(hook).and_return(setup_service)
      end

      context 'when setup raises an error' do
        it 'captures exception and logs error' do
          error = StandardError.new('Test error')
          allow(setup_service).to receive(:setup).and_raise(error)
          allow(Rails.logger).to receive(:error)
          allow(ChatwootExceptionTracker).to receive(:new)
            .with(error, account: hook.account)
            .and_return(instance_double(ChatwootExceptionTracker, capture_exception: true))

          described_class.new.perform(hook.id)

          expect(Rails.logger).to have_received(:error)
            .with("Error in CRM setup for hook ##{hook.id} (#{hook.app_id}): Test error")
        end
      end
    end
  end
end
