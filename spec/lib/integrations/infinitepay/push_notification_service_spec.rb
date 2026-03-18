require 'rails_helper'

describe Integrations::Infinitepay::PushNotificationService do
  let(:account) { create(:account, custom_attributes: { 'infinitepay_push_only' => push_only_enabled }) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:payment_link) do
    PaymentLink.create!(
      account: account,
      conversation: conversation,
      user: user,
      order_nsu: 'chatwit-1-1-abc123',
      amount_cents: 2790,
      description: 'analise',
      checkout_url: 'https://checkout.infinitepay.io/test',
      status: 'paid'
    )
  end
  let(:notification_payload) do
    {
      title: 'Pagamento Confirmado!',
      body: "Ola Nonata, seu pagamento foi recebido com sucesso!",
      tag: 'infinitepay_payment_confirmed_1',
      url: 'https://chatwit.witdev.com.br/app/accounts/3/conversations/1'
    }
  end
  let(:push_only_enabled) { true }

  before do
    allow(InstallationConfig).to receive(:find_by).and_call_original
    allow(InstallationConfig).to receive(:find_by)
      .with(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
      .and_return(nil)
    allow(InstallationConfig).to receive(:find_by)
      .with(name: 'INSTALLATION_PRICING_PLAN')
      .and_return(nil)
    allow(WebPush).to receive(:payload_send).and_return(true)
    allow(Rails.logger).to receive(:info)
    create(
      :notification_subscription,
      :browser_push,
      user: user,
      subscription_attributes: {
        endpoint: 'https://example.com/push',
        p256dh: 'test-p256dh',
        auth: 'test-auth'
      }
    )
  end

  it 'sends browser push notifications to account users when exclusive infinitepay push is enabled' do
    with_modified_env VAPID_PUBLIC_KEY: 'test-public-key', VAPID_PRIVATE_KEY: 'test-private-key' do
      described_class.new(payment_link: payment_link, notification_payload: notification_payload).perform

      expect(WebPush).to have_received(:payload_send)
      expect(Rails.logger).to have_received(:info).with(
        "[INFINITEPAY-PUSH] Browser push sent to #{user.email} for payment_link=#{payment_link.id}"
      )
    end
  end

  context 'when exclusive infinitepay push is disabled' do
    let(:push_only_enabled) { false }

    it 'does not send browser push notifications' do
      with_modified_env VAPID_PUBLIC_KEY: 'test-public-key', VAPID_PRIVATE_KEY: 'test-private-key' do
        described_class.new(payment_link: payment_link, notification_payload: notification_payload).perform

        expect(WebPush).not_to have_received(:payload_send)
      end
    end
  end
end