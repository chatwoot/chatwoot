require 'rails_helper'

RSpec.describe SlackUnfurlJob do
  subject(:job) { described_class.perform_later(params: link_shared, integration_hook: hook) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let!(:conversation) { create(:conversation, inbox: inbox) }
  let(:slack_client) { double }
  let(:link_shared) do
    {
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: {
        type: 'link_shared',
        user: 'ULYPAKE5S',
        source: 'conversations_history',
        unfurl_id: 'C7NQEAE5Q.1695111587.937099.7e240338c6d2053fb49f56808e7c1f619f6ef317c39ebc59fc4af1cc30dce49b',
        channel: 'G01354F6A6Q',
        links: [{
          url: "https://qa.chatwoot.com/app/accounts/#{hook.account_id}/conversations/#{conversation.display_id}",
          domain: 'qa.chatwoot.com'
        }]
      },
      type: 'event_callback',
      event_time: 1_588_623_033
    }
  end

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .on_queue('low')
  end

  context 'when the calls the slack unfurl job' do
    it 'does the unfurl when the url shared in the same channel' do
      slack_link_unfurl_service = instance_double(Integrations::Slack::SlackLinkUnfurlService)

      expected_body = {
        channel: link_shared[:event][:channel]
      }

      stub_request(:post, 'https://slack.com/api/conversations.members')
        .with(body: expected_body)
        .to_return(status: 200, body: { 'ok' => true }.to_json, headers: {})

      expect(Integrations::Slack::SlackLinkUnfurlService).to receive(:new)
        .with(params: link_shared, integration_hook: hook)
        .and_return(slack_link_unfurl_service)
      expect(slack_link_unfurl_service).to receive(:perform)
      described_class.perform_now(link_shared)
    end

    it 'does the unfurl when the url shared in the different channel under same account' do
      slack_link_unfurl_service = instance_double(Integrations::Slack::SlackLinkUnfurlService)

      expected_body = {
        channel: 'XSDSFSFS'
      }

      link_shared[:event][:channel] = 'XSDSFSFS'

      stub_request(:post, 'https://slack.com/api/conversations.members')
        .with(body: expected_body)
        .to_return(status: 200, body: { 'ok' => true }.to_json, headers: {})
      expect(Integrations::Slack::SlackLinkUnfurlService).to receive(:new)
        .with(params: link_shared, integration_hook: hook)
        .and_return(slack_link_unfurl_service)

      expect(slack_link_unfurl_service).to receive(:perform)
      described_class.perform_now(link_shared)
    end
  end
end
