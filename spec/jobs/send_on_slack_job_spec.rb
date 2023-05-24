require 'rails_helper'

RSpec.describe SendOnSlackJob do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:event_name) { 'message.created' }
  let(:event_data) { { message: create(:message, account: account, content: 'muchas muchas gracias', message_type: :incoming) } }

  context 'when handleable events like message.created' do
    let(:process_service) { double }

    before do
      stub_request(:post, 'https://slack.com/api/chat.postMessage')
      allow(process_service).to receive(:perform)
    end

    it 'calls Integrations::Slack::SendOnSlackService when its a slack hook' do
      hook = create(:integrations_hook, app_id: 'slack', account: account)
      slack_service_instance = Integrations::Slack::SendOnSlackService.new(message: event_data[:message], hook: hook)
      expect(Integrations::Slack::SendOnSlackService).to receive(:new).with(message: event_data[:message],
                                                                            hook: hook).and_return(slack_service_instance)
      described_class.perform_now(event_data[:message], hook)
    end

    it 'calls Integrations::Slack::SendOnSlackService when its a slack hook for template message' do
      event_data = { message: create(:message, account: account, message_type: :template) }
      hook = create(:integrations_hook, app_id: 'slack', account: account)
      slack_service_instance = Integrations::Slack::SendOnSlackService.new(message: event_data[:message], hook: hook)
      expect(Integrations::Slack::SendOnSlackService).to receive(:new).with(message: event_data[:message],
                                                                            hook: hook).and_return(slack_service_instance)
      described_class.perform_now(event_data[:message], hook)
    end
  end
end
