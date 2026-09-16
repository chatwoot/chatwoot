require 'rails_helper'

RSpec.describe UpdateSlackMessageJob do
  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, app_id: 'slack', account: account) }
  let(:message) do
    create(:message, account: account, content: 'Pick one', message_type: :outgoing, content_type: :input_select,
                     content_attributes: { items: [{ title: 'Option A', value: 'a' }] })
  end

  before do
    stub_request(:post, 'https://slack.com/api/chat.update')
  end

  it 'calls Integrations::Slack::UpdateSlackMessageService' do
    service_instance = Integrations::Slack::UpdateSlackMessageService.new(message: message, hook: hook)
    expect(Integrations::Slack::UpdateSlackMessageService).to receive(:new).with(message: message, hook: hook).and_return(service_instance)

    described_class.perform_now(message, hook)
  end
end
