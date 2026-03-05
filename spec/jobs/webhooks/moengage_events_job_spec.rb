require 'rails_helper'

RSpec.describe Webhooks::MoengageEventsJob do
  subject(:job) { described_class.perform_later(params) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:webhook_token) { SecureRandom.urlsafe_base64(32) }
  let!(:hook) do
    create(:integrations_hook,
           account: account,
           app_id: 'moengage',
           settings: {
             'workspace_id' => 'test-workspace',
             'webhook_token' => webhook_token,
             'default_inbox_id' => inbox.id,
             'auto_create_contact' => true,
             'enable_ai_response' => false
           })
  end

  let(:params) do
    {
      'webhook_token' => webhook_token,
      'event_name' => 'cart_abandoned',
      'customer' => {
        'email' => 'test@example.com',
        'first_name' => 'John'
      }
    }
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(params)
      .on_queue('default')
  end

  context 'when invalid params' do
    it 'returns nil when no webhook_token' do
      expect(described_class.perform_now({})).to be_nil
    end

    it 'logs a warning when hook is not found' do
      expect(Rails.logger).to receive(:warn).with(/MoEngage event discarded.*Hook not found for webhook_token: invalid/)
      described_class.perform_now({ 'webhook_token' => 'invalid' }.with_indifferent_access)
    end
  end

  context 'when valid params' do
    it 'calls WebhookProcessorService' do
      process_service = double
      allow(Integrations::Moengage::WebhookProcessorService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)

      expect(Integrations::Moengage::WebhookProcessorService).to receive(:new).with(
        hook: hook,
        payload: hash_including('event_name' => 'cart_abandoned')
      )
      expect(process_service).to receive(:perform)

      described_class.perform_now(params.with_indifferent_access)
    end

    it 'logs a warning and does not process events if account is suspended' do
      account.update!(status: :suspended)

      process_service = double
      allow(Integrations::Moengage::WebhookProcessorService).to receive(:new).and_return(process_service)
      allow(process_service).to receive(:perform)

      expect(Rails.logger).to receive(:warn).with(/MoEngage event discarded.*Account #{account.id} is not active/)
      expect(Integrations::Moengage::WebhookProcessorService).not_to receive(:new)

      described_class.perform_now(params.with_indifferent_access)
    end
  end

  context 'when hook is disabled' do
    before { hook.update!(status: :disabled) }

    it 'logs a warning and does not process events' do
      expect(Rails.logger).to receive(:warn).with(/MoEngage event discarded.*Hook not found/)
      expect(Integrations::Moengage::WebhookProcessorService).not_to receive(:new)

      described_class.perform_now(params.with_indifferent_access)
    end
  end
end
