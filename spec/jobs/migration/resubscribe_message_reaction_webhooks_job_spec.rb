require 'rails_helper'

RSpec.describe Migration::ResubscribeMessageReactionWebhooksJob do
  let(:facebook_channel) { create(:channel_facebook_page) }
  let(:instagram_channel) { create(:channel_instagram) }
  let(:telegram_channel) { create(:channel_telegram) }
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }

  before do
    stub_request(:post, /graph.facebook.com/)

    # Control exactly which (already-created) channel instances the job iterates over,
    # so per-test stubs on those instances are the ones actually invoked.
    allow(Channel::FacebookPage).to receive(:find_each).and_yield(facebook_channel)
    allow(Channel::Instagram).to receive(:find_each).and_yield(instagram_channel)
    allow(Channel::Telegram).to receive(:find_each).and_yield(telegram_channel)

    allow(Channel::Whatsapp).to receive(:find_each).and_yield(whatsapp_channel)

    webhook_setup_service = instance_double(Whatsapp::WebhookSetupService, perform: true)
    allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_setup_service)

    allow(instagram_channel).to receive(:subscribe).and_return(true)
  end

  it 'continues resubscribing other channels when one channel raises' do
    allow(facebook_channel).to receive(:subscribe).and_raise(StandardError, 'boom')
    allow(telegram_channel).to receive(:setup_telegram_webhook).and_return(true)

    expect { described_class.perform_now }.not_to raise_error
    expect(telegram_channel).to have_received(:setup_telegram_webhook)
  end

  it 'returns and logs stats counting checked, succeeded, and failed channels' do
    allow(facebook_channel).to receive(:subscribe).and_raise(StandardError, 'boom')
    allow(telegram_channel).to receive(:setup_telegram_webhook).and_return(true)
    allow(Rails.logger).to receive(:info)

    stats = described_class.perform_now

    expect(Rails.logger).to have_received(:info).with(/\[MessageReactions\] Resubscribe complete:/)
    expect(stats).to eq(checked: 4, succeeded: 3, failed: 1, skipped: 0)
  end

  it 'counts non whatsapp_cloud channels as skipped rather than processing them' do
    allow(facebook_channel).to receive(:subscribe).and_return(true)
    allow(telegram_channel).to receive(:setup_telegram_webhook).and_return(true)
    allow(whatsapp_channel).to receive(:provider).and_return('default')

    stats = described_class.perform_now

    expect(Whatsapp::WebhookSetupService).not_to have_received(:new)
    expect(stats).to eq(checked: 4, succeeded: 3, failed: 0, skipped: 1)
  end

  it 'counts a Telegram webhook setup failure as failed without raising' do
    allow(facebook_channel).to receive(:subscribe).and_return(true)

    telegram_channel.singleton_class.send(:remove_method, :setup_telegram_webhook)
    stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/deleteWebhook")
    stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/setWebhook")
      .to_return(status: 400, body: { ok: false }.to_json, headers: { 'Content-Type' => 'application/json' })

    allow(Rails.logger).to receive(:error)

    stats = nil
    expect { stats = described_class.perform_now }.not_to raise_error

    expect(Rails.logger).to have_received(:error).with(/Failed to resubscribe channel Channel::Telegram##{telegram_channel.id}/)

    expect(stats).to eq(checked: 4, succeeded: 3, failed: 1, skipped: 0)
  end

  it 'subscribes Facebook pages with message_reactions in the field list' do
    expect(Facebook::Messenger::Subscriptions).to receive(:subscribe).with(
      access_token: facebook_channel.page_access_token,
      subscribed_fields: include('message_reactions')
    )
    allow(telegram_channel).to receive(:setup_telegram_webhook).and_return(true)

    described_class.perform_now
  end

  it 'sets up the Telegram webhook with message_reaction in allowed_updates' do
    allow(facebook_channel).to receive(:subscribe).and_return(true)

    # The factory stubs setup_telegram_webhook (as a singleton method) to skip real HTTP
    # calls during creation; remove that stub here so the job exercises the real method.
    telegram_channel.singleton_class.send(:remove_method, :setup_telegram_webhook)

    delete_stub = stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/deleteWebhook")
                  .to_return(status: 200, body: { ok: true }.to_json, headers: { 'Content-Type' => 'application/json' })
    set_webhook_stub = stub_request(:post, "https://api.telegram.org/bot#{telegram_channel.bot_token}/setWebhook")
                       .with(
                         body: {
                           url: "#{ENV.fetch('FRONTEND_URL', nil)}/webhooks/telegram/#{telegram_channel.bot_token}",
                           allowed_updates: Channel::Telegram::ALLOWED_WEBHOOK_UPDATES.to_json
                         }
                       )
                       .to_return(status: 200, body: { ok: true }.to_json, headers: { 'Content-Type' => 'application/json' })

    expect(Channel::Telegram::ALLOWED_WEBHOOK_UPDATES).to include('message_reaction')

    described_class.perform_now

    expect(delete_stub).to have_been_requested
    expect(set_webhook_stub).to have_been_requested
  end

  it 'sets up webhooks for whatsapp_cloud channels' do
    allow(facebook_channel).to receive(:subscribe).and_return(true)
    allow(telegram_channel).to receive(:setup_telegram_webhook).and_return(true)

    described_class.perform_now

    expect(Whatsapp::WebhookSetupService).to have_received(:new).with(
      whatsapp_channel, whatsapp_channel.provider_config['business_account_id'], whatsapp_channel.provider_config['api_key']
    )
  end

  it 'is safe to run twice' do
    allow(facebook_channel).to receive(:subscribe).and_return(true)
    allow(telegram_channel).to receive(:setup_telegram_webhook).and_return(true)

    expect do
      described_class.perform_now
      described_class.perform_now
    end.not_to raise_error
  end
end
