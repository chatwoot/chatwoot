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
  let(:token) { SecureRandom.uuid }

  before do
    allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
    allow(ActiveRecord).to receive(:after_all_transactions_commit).and_yield
    account.enable_features!('captain_integration')
    account.claim_captain_response_usage_alert(token)
    allow(AdministratorNotifications::CaptainNotificationMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:response_usage_alert).and_return(message_delivery)
  end

  it 'sends a claimed alert once across repeated checks' do
    2.times { described_class.perform_now(account.id, token) }

    expect(AdministratorNotifications::CaptainNotificationMailer).to have_received(:with).with(account: account).once
    expect(mailer).to have_received(:response_usage_alert).with(consumed: 241, remaining: 59).once
    expect(message_delivery).to have_received(:deliver_now).once
    expect(account.reload.custom_attributes).to include(
      'captain_responses_usage_alerted' => true,
      'captain_responses_usage_alert_claim' => false,
      'unrelated_key' => 'preserved'
    )
  end

  it 'allows only one queued job to claim an eligible account' do
    account.release_captain_response_usage_alert(token)
    allow(described_class).to receive(:perform_later).and_return(true)

    expect(described_class.enqueue_for_account(account)).to be(true)
    expect(described_class.enqueue_for_account(account)).to be(false)
    expect(described_class).to have_received(:perform_later).once
  end

  it 'releases the claim when a deferred enqueue is rejected after commit' do
    account.release_captain_response_usage_alert(token)
    after_commit = nil
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&callback| after_commit = callback }
    allow(described_class).to receive(:perform_later).and_return(false)

    expect(described_class.enqueue_for_account(account)).to be(true)
    expect(account.reload.custom_attributes['captain_responses_usage_alert_claim']).to be_present

    expect { after_commit.call }.to change {
      account.reload.custom_attributes['captain_responses_usage_alert_claim']
    }.to(false)
  end

  it 'releases the claim when a deferred enqueue raises after commit' do
    account.release_captain_response_usage_alert(token)
    after_commit = nil
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&callback| after_commit = callback }
    allow(described_class).to receive(:perform_later).and_raise(StandardError, 'queue unavailable')

    expect(described_class.enqueue_for_account(account)).to be(true)

    expect { after_commit.call }.to raise_error(StandardError, 'queue unavailable')
    expect(account.reload.custom_attributes['captain_responses_usage_alert_claim']).to be(false)
  end

  it 'releases a failed delivery claim and lets the retry reclaim it' do
    delivery_attempts = 0
    allow(message_delivery).to receive(:deliver_now) do
      delivery_attempts += 1
      raise StandardError, 'delivery failed' if delivery_attempts == 1

      true
    end

    expect { described_class.perform_now(account.id, token) }.to raise_error(StandardError, 'delivery failed')
    expect(account.reload.custom_attributes).to include(
      'captain_responses_usage_alert_claim' => false
    )

    described_class.perform_now(account.id, token)

    expect(message_delivery).to have_received(:deliver_now).twice
    expect(account.reload.custom_attributes).to include(
      'captain_responses_usage_alerted' => true,
      'captain_responses_usage_alert_claim' => false
    )
  end

  it 'rechecks the current balance before claiming the alert' do
    account.update!(limits: { 'captain_responses' => 1000 })

    described_class.perform_now(account.id, token)

    expect(AdministratorNotifications::CaptainNotificationMailer).not_to have_received(:with)
    expect(account.reload.custom_attributes).to include(
      'captain_responses_usage_alert_claim' => false
    )
  end

  it 'rechecks Captain eligibility before claiming the alert' do
    account.disable_features!('captain_integration')

    described_class.perform_now(account.id, token)

    expect(AdministratorNotifications::CaptainNotificationMailer).not_to have_received(:with)
    expect(account.reload.custom_attributes).to include(
      'captain_responses_usage_alert_claim' => false
    )
  end
end
