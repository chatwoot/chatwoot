require 'rails_helper'

describe Twitter::WebhookSubscribeService do
  subject(:webhook_subscribe_service) { described_class.new(inbox_id: twitter_inbox.id) }

  let(:twitter_client) { instance_double(Twitty::Facade) }
  let(:twitter_success_response) { instance_double(Twitty::Response, status: '200', body: { message: 'Valid' }) }
  let(:twitter_error_response) { instance_double(Twitty::Response, status: '422', body: { message: 'Invalid request' }) }
  let(:account) { create(:account) }
  let(:twitter_channel) { create(:channel_twitter_profile, account: account) }
  let(:twitter_inbox) { create(:inbox, channel: twitter_channel, account: account) }

  before do
    allow(Twitty::Facade).to receive(:new).and_return(twitter_client)
    allow(twitter_client).to receive(:register_webhook).and_return(twitter_success_response)
    allow(twitter_client).to receive(:unregister_webhook).and_return(twitter_success_response)
    allow(twitter_client).to receive(:fetch_subscriptions).and_return(instance_double(Twitty::Response, status: '204', body: { message: 'Valid' }))
    allow(twitter_client).to receive(:create_subscription).and_return(instance_double(Twitty::Response, status: '204', body: { message: 'Valid' }))
  end

  describe '#perform' do
    context 'when webhook is not registered' do
      it 'calls register_webhook' do
        allow(twitter_client).to receive(:fetch_webhooks).and_return(
          instance_double(Twitty::Response, status: '200', body: {})
        )
        webhook_subscribe_service.perform
        expect(twitter_client).not_to have_received(:unregister_webhook)
        expect(twitter_client).to have_received(:register_webhook)
      end
    end

    context 'when valid webhook is registered' do
      it 'calls unregister_webhook and then register webhook' do
        allow(twitter_client).to receive(:fetch_webhooks).and_return(
          instance_double(Twitty::Response, status: '200',
                                            body: [{ 'url' => webhook_subscribe_service.send(:twitter_url) }])
        )
        webhook_subscribe_service.perform
        expect(twitter_client).not_to have_received(:unregister_webhook)
        expect(twitter_client).not_to have_received(:register_webhook)
      end
    end

    context 'when invalid webhook is registered' do
      it 'calls unregister_webhook and then register webhook' do
        allow(twitter_client).to receive(:fetch_webhooks).and_return(
          instance_double(Twitty::Response, status: '200',
                                            body: [{ 'url' => 'invalid_url' }])
        )
        webhook_subscribe_service.perform
        expect(twitter_client).to have_received(:unregister_webhook)
        expect(twitter_client).to have_received(:register_webhook)
      end
    end

    context 'when correct webhook is present' do
      it 'calls create subscription if subscription is not present' do
        allow(twitter_client).to receive(:fetch_webhooks).and_return(
          instance_double(Twitty::Response, status: '200',
                                            body: [{ 'url' => webhook_subscribe_service.send(:twitter_url) }])
        )
        allow(twitter_client).to receive(:fetch_subscriptions).and_return(instance_double(Twitty::Response, status: '500'))
        webhook_subscribe_service.perform
        expect(twitter_client).to have_received(:create_subscription)
      end

      it 'does not call create subscription if subscription is already present' do
        allow(twitter_client).to receive(:fetch_webhooks).and_return(
          instance_double(Twitty::Response, status: '200',
                                            body: [{ 'url' => webhook_subscribe_service.send(:twitter_url) }])
        )
        webhook_subscribe_service.perform
        expect(twitter_client).not_to have_received(:create_subscription)
      end
    end
  end
end
