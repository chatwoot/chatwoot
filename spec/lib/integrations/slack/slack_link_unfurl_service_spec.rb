require 'rails_helper'

describe Integrations::Slack::SlackLinkUnfurlService do
  let!(:contact) { create(:contact) }
  let(:channel_email) { create(:channel_email) }
  let!(:conversation) { create(:conversation, inbox: channel_email.inbox, contact: contact, identifier: nil) }
  let(:account) { conversation.account }
  let!(:hook) { create(:integrations_hook, account: account) }
  let(:expected_headers) { { 'Authorization' => "Bearer #{hook.settings['api_key']}" } }

  let(:link_unufurl_response) do
    {
      'ok': true
    }.to_json
  end

  let(:link_shared) do
    {
      team_id: 'TLST3048H',
      api_app_id: 'A012S5UETV4',
      event: link_shared_event.merge({ links: [{ url: "https://qa.chatwoot.com/app/accounts/1/conversations/#{conversation.display_id}",
                                                 domain: 'qa.chatwoot.com' }] }),
      type: 'event_callback',
      event_time: 1_588_623_033
    }
  end

  let(:slack_client) { double }
  let(:link_builder) { described_class.new(params: link_shared, integration_hook: hook) }

  describe '#perform' do
    it 'when the event is unfurl' do
      request_body = {
        'source' => 'conversations_history',
        'unfurl_id' => 'C7NQEAE5Q.1695111587.937099.7e240338c6d2053fb49f56808e7c1f619f6ef317c39ebc59fc4af1cc30dce49b',
        'unfurls' => {
          'https://qa.chatwoot.com/app/accounts/1/conversations/1' => {
            'blocks' => [
              {
                'type' => 'section',
                'fields' => [
                  {
                    'type' => 'mrkdwn',
                    'text' => "*Name:*\nContact 52"
                  },
                  {
                    'type' => 'mrkdwn',
                    'text' => "*Email:*\n---"
                  },
                  {
                    'type' => 'mrkdwn',
                    'text' => "*Phone:*\n---"
                  },
                  {
                    'type' => 'mrkdwn',
                    'text' => "*Company:*\n---"
                  }
                ]
              },
              {
                'type' => 'actions',
                'elements' => [
                  {
                    'type' => 'button',
                    'text' => {
                      'type' => 'plain_text',
                      'text' => 'Open conversation',
                      'emoji' => true
                    },
                    'url' => 'https://qa.chatwoot.com/app/accounts/1/conversations/1',
                    'action_id' => 'button-action'
                  }
                ]
              }
            ]
          }
        }
      }

      stub_request(:post, 'https://slack.com/api/chat.unfurl')
        .with(
          body: anything,
          headers: expected_headers
        )
        .to_return(status: 200, body: link_unufurl_response, headers: {})
        # link_builder.perform
    end
  end
end
