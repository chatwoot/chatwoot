require 'rails_helper'

RSpec.describe Internal::AccountAnalysis::DiscordNotifierService do
  let(:service) { described_class.new }
  let(:webhook_url) { 'https://discord.com/api/webhooks/123456789/some-token' }
  let(:account) do
    create(
      :account,
      internal_attributes: {
        'last_threat_scan_level' => 'high',
        'last_threat_scan_recommendation' => 'review',
        'illegal_activities_detected' => true,
        'last_threat_scan_summary' => 'Suspicious activity detected'
      }
    )
  end
  let!(:user) { create(:user, account: account) }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#notify_flagged_account' do
    context 'when webhook URL is configured' do
      before do
        create(:installation_config, name: 'ACCOUNT_SECURITY_NOTIFICATION_WEBHOOK_URL', value: webhook_url)
        stub_request(:post, webhook_url).to_return(status: 200)
      end

      it 'sends notification to Discord webhook' do
        service.notify_flagged_account(account)
        expect(WebMock).to have_requested(:post, webhook_url)
          .with(
            body: hash_including(
              content: include(
                "Account ID: #{account.id}",
                "User Email: #{user.email}",
                'Threat Level: high',
                '**System Recommendation:** review',
                '⚠️ Potential illegal activities detected',
                'Suspicious activity detected'
              )
            )
          )
      end
    end

    context 'when webhook URL is not configured' do
      it 'logs error and does not make HTTP request' do
        service.notify_flagged_account(account)

        expect(Rails.logger).to have_received(:error)
          .with('Cannot send Discord notification: No webhook URL configured')
        expect(WebMock).not_to have_requested(:post, webhook_url)
      end
    end

    context 'when HTTP request fails' do
      before do
        create(:installation_config, name: 'ACCOUNT_SECURITY_NOTIFICATION_WEBHOOK_URL', value: webhook_url)
        stub_request(:post, webhook_url).to_raise(StandardError.new('Connection failed'))
      end

      it 'catches exception and logs error' do
        service.notify_flagged_account(account)

        expect(Rails.logger).to have_received(:error)
          .with('Error sending Discord notification: Connection failed')
      end
    end
  end
end
