require 'rails_helper'

RSpec.describe Integrations::Stripe::UninstallationService do
  let(:connected_at) { Time.iso8601('2026-10-15T06:00:00.900Z') }
  let!(:hook) do
    create(:integrations_hook, app_id: 'stripe', reference_id: 'acct_reconnected', access_token: 'replacement-token',
                               settings: { 'livemode' => false, 'connected_at' => connected_at.iso8601 })
  end
  let(:event) { Stripe::Event.construct_from(account: hook.reference_id, livemode: false, created: event_created) }

  context 'when an earlier uninstall and a reconnection share the same timestamp second' do
    let(:event_created) { connected_at.to_i }

    it 'preserves the replacement credentials, including on repeated delivery' do
      2.times { described_class.new(event: event).perform }
      expect(hook.reload.access_token).to eq('replacement-token')
    end
  end

  context 'when the uninstall predates the reconnection' do
    let(:event_created) { connected_at.to_i - 1 }

    it 'preserves the connection' do
      expect { described_class.new(event: event).perform }.not_to change(Integrations::Hook, :count)
    end
  end

  context 'when the uninstall is newer than the connection' do
    let(:event_created) { connected_at.to_i + 1 }

    it 'removes the saved connection and tolerates repeated delivery' do
      service = described_class.new(event: event)
      expect { service.perform }.to change(Integrations::Hook, :count).by(-1)
      expect { service.perform }.not_to change(Integrations::Hook, :count)
    end
  end
end
