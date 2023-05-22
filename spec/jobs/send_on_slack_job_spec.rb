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
      allow(process_service).to receive(:perform)
    end

    it 'calls Integrations::Slack::SendOnSlackService when its a slack hook' do
      hook = create(:integrations_hook, app_id: 'slack', account: account)
      allow(Integrations::Slack::SendOnSlackService).to receive(:new).and_return(process_service)
      expect(Integrations::Slack::SendOnSlackService).to receive(:new).with(message: event_data[:message], hook: hook)
      described_class.perform_now(message: event_data[:message], hook: hook)
    end

    it 'calls Integrations::Slack::SendOnSlackService when its a slack hook for template message' do
      event_data = { message: create(:message, account: account, message_type: :template) }
      hook = create(:integrations_hook, app_id: 'slack', account: account)
      allow(Integrations::Slack::SendOnSlackService).to receive(:new).and_return(process_service)
      expect(Integrations::Slack::SendOnSlackService).to receive(:new).with(message: event_data[:message], hook: hook)
      described_class.perform_now(message: event_data[:message], hook: hook)
    end
  end
end
