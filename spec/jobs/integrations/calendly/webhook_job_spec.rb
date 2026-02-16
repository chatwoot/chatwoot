require 'rails_helper'

RSpec.describe Integrations::Calendly::WebhookJob do
  let(:account) { create(:account) }
  let(:hook) do
    create(:integrations_hook,
           account: account,
           app_id: 'calendly',
           access_token: 'test-token',
           settings: {
             'calendly_user_uri' => 'https://api.calendly.com/users/ABC123',
             'signing_key' => SecureRandom.hex(32)
           })
  end

  let(:event) { 'invitee.created' }
  let(:payload) do
    {
      'email' => 'customer@example.com',
      'name' => 'Jane Smith',
      'event' => 'https://api.calendly.com/scheduled_events/EV123'
    }
  end
  let(:payload_json) { payload.to_json }

  it 'enqueues on the default queue' do
    expect(described_class.new.queue_name).to eq('default')
  end

  it 'delegates to WebhookProcessorService with correct params' do
    service = instance_double(Integrations::Calendly::WebhookProcessorService)
    allow(Integrations::Calendly::WebhookProcessorService).to receive(:new)
      .with(hook: hook, event: event, payload: payload)
      .and_return(service)
    allow(service).to receive(:perform)

    described_class.perform_now(hook, event, payload_json)

    expect(service).to have_received(:perform)
  end
end
