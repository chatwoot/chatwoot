require 'rails_helper'

describe ::Twitter::WebhookSubscribeService do
  subject(:webhook_subscribe_service) { described_class.new(inbox_id: twitter_inbox.id) }

  let(:twitter_client) { instance_double(::Twitty::Facade) }
  let(:twitter_success_response) { instance_double(::Twitty::Response, status: '200', body: { message: 'Valid' }) }
  let(:twitter_error_response) { instance_double(::Twitty::Response, status: '422', body: { message: 'Invalid request' }) }
  let(:account) { create(:account) }
  let(:twitter_channel) { create(:channel_twitter_profile, account: account) }
  let(:twitter_inbox) { create(:inbox, channel: twitter_channel, account: account) }

  before do
    allow(::Twitty::Facade).to receive(:new).and_return(twitter_client)
    allow(twitter_client).to receive(:register_webhook)
    allow(twitter_client).to receive(:subscribe_webhook)
  end

  describe '#perform' do
    context 'with successful registration' do
      it 'calls subscribe webhook' do
        allow(twitter_client).to receive(:register_webhook).and_return(twitter_success_response)
        webhook_subscribe_service.perform
        expect(twitter_client).to have_received(:subscribe_webhook)
      end
    end

    context 'with unsuccessful registration' do
      it 'does not call subscribe webhook' do
        allow(twitter_client).to receive(:register_webhook).and_return(twitter_error_response)
        webhook_subscribe_service.perform
        expect(twitter_client).not_to have_received(:subscribe_webhook)
      end
    end
  end
end
