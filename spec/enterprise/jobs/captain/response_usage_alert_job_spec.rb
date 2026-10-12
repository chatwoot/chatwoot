require 'rails_helper'

RSpec.describe Captain::ResponseUsageAlertJob do
  let(:account) do
    create(
      :account,
      limits: { 'captain_responses' => 300 },
      custom_attributes: {
        'captain_responses_usage' => 241,
        'unrelated_key' => 'preserved'
      }
    )
  end
  let(:mailer) { double }
  let(:message_delivery) { instance_double(ActionMailer::MessageDelivery, deliver_now: true) }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    account.enable_features!('captain_integration')
    allow(AdministratorNotifications::CaptainNotificationMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:response_usage_alert).and_return(message_delivery)
  end

  it 'claims and sends the alert once across repeated checks' do
    2.times { described_class.perform_now(account.id) }

    expect(AdministratorNotifications::CaptainNotificationMailer).to have_received(:with).with(account: account).once
    expect(mailer).to have_received(:response_usage_alert).with(consumed: 241, remaining: 59).once
    expect(message_delivery).to have_received(:deliver_now).once
    expect(account.reload.custom_attributes).to include(
      'captain_responses_usage_alerted' => true,
      'unrelated_key' => 'preserved'
    )
  end

  it 'rechecks the current balance before claiming the alert' do
    account.update!(limits: { 'captain_responses' => 1000 })

    described_class.perform_now(account.id)

    expect(AdministratorNotifications::CaptainNotificationMailer).not_to have_received(:with)
    expect(account.reload.custom_attributes['captain_responses_usage_alerted']).to be_nil
  end

  it 'rechecks Captain eligibility before claiming the alert' do
    account.disable_features!('captain_integration')

    described_class.perform_now(account.id)

    expect(AdministratorNotifications::CaptainNotificationMailer).not_to have_received(:with)
    expect(account.reload.custom_attributes['captain_responses_usage_alerted']).to be_nil
  end
end
