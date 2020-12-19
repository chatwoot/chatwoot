require 'rails_helper'
describe InstallationWebhookListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:event) { Events::Base.new(event_name, Time.zone.now, account: account) }

  describe '#account_created' do
    let(:event_name) { :'account.created' }

    context 'when installation config is not configured' do
      it 'does not trigger webhook' do
        expect(WebhookJob).to receive(:perform_later).exactly(0).times
        listener.account_created(event)
      end
    end

    context 'when installation config is configured' do
      it 'triggers webhook' do
        create(:installation_config, name: 'INSTALLATION_EVENTS_WEBHOOK_URL', value: 'https://test.com')
        expect(WebhookJob).to receive(:perform_later).with('https://test.com', account.webhook_data.merge(event: 'account_created', users: [])).once
        listener.account_created(event)
      end
    end
  end
end
