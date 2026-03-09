require 'rails_helper'

describe Integrations::Slack::SlackLinkUnfurlService do
  let!(:contact) { create(:contact, name: 'Contact 1', email: nil, phone_number: nil) }
  let(:channel_email) { create(:channel_email) }
  let!(:conversation) { create(:conversation, inbox: channel_email.inbox, contact: contact, identifier: nil) }
  let(:account) { conversation.account }
  let!(:hook) { create(:integrations_hook, account: account) }

  describe '#perform' do
    context 'when the event does not contain any link' do
      let(:link_shared) do
        {
          team_id: 'TLST3048H',
          api_app_id: 'A012S5UETV4',
          event: link_shared_event.merge(links: []),
          type: 'event_callback',
          event_time: 1_588_623_033
        }
      end
      let(:link_builder) { described_class.new(params: link_shared, integration_hook: hook) }

      it 'does not send a POST request to Slack API' do
        result = link_builder.perform
        expect(result).to eq([])
      end
    end

    context 'when the event link contains the account id which does not match the integration hook account id' do
      let(:link_shared) do
        {
          team_id: 'TLST3048H',
          api_app_id: 'A012S5UETV4',
          event: link_shared_event.merge(links: [{
                                           url: "https://qa.chatwoot.com/app/accounts/1212/conversations/#{conversation.display_id}",
                                           domain: 'qa.chatwoot.com'
                                         }], channel: 'G054F6A6Q'),
          type: 'event_callback',
          event_time: 1_588_623_033
        }
      end
      let(:link_builder) { described_class.new(params: link_shared, integration_hook: hook) }

      it 'does not send a POST request to Slack API' do
        link_builder.perform
        expect(link_builder).not_to receive(:unfurl_link)
      end
    end

    context 'when the event link contains the conversation id which does not belong to the account' do
      let(:link_shared) do
        {
          team_id: 'TLST3048H',
          api_app_id: 'A012S5UETV4',
          event: link_shared_event.merge(links: [{
                                           url: 'https://qa.chatwoot.com/app/accounts/1/conversations/1213',
                                           domain: 'qa.chatwoot.com'
                                         }], channel: 'G054F6A6Q'),
          type: 'event_callback',
          event_time: 1_588_623_033
        }
      end
      let(:link_builder) { described_class.new(params: link_shared, integration_hook: hook) }

      it 'does not send a POST request to Slack API' do
        link_builder.perform
        expect(link_builder).not_to receive(:unfurl_link)
      end
    end

    context 'when the event contains containing single link' do
      let(:link_shared) do
        {
          team_id: 'TLST3048H',
          api_app_id: 'A012S5UETV4',
          event: link_shared_event.merge(links: [{
                                           url: "https://qa.chatwoot.com/app/accounts/1/conversations/#{conversation.display_id}",
                                           domain: 'qa.chatwoot.com'
                                         }]),
          type: 'event_callback',
          event_time: 1_588_623_033
        }
      end
      let(:link_builder) { described_class.new(params: link_shared, integration_hook: hook) }

      it 'sends a POST unfurl request to Slack' do
        expected_body = {
          'source' => 'conversations_history',
          'unfurl_id' => 'C7NQEAE5Q.1695111587.937099.7e240338c6d2053fb49f56808e7c1f619f6ef317c39ebc59fc4af1cc30dce49b',
          'unfurls' => '{"https://qa.chatwoot.com/app/accounts/1/conversations/1":' \
                       '{"blocks":[{' \
                       '"type":"section",' \
                       '"fields":[{' \
                       '"type":"mrkdwn",' \
                       "\"text\":\"*Name:*\\n#{contact.name}\"}," \
                       '{"type":"mrkdwn","text":"*Email:*\\n---"},' \
                       '{"type":"mrkdwn","text":"*Phone:*\\n---"},' \
                       '{"type":"mrkdwn","text":"*Company:*\\n---"},' \
                       "{\"type\":\"mrkdwn\",\"text\":\"*Inbox:*\\n#{channel_email.inbox.name}\"}," \
                       "{\"type\":\"mrkdwn\",\"text\":\"*Inbox Type:*\\n#{channel_email.inbox.channel.name}\"}]}," \
                       '{"type":"actions","elements":[{' \
                       '"type":"button",' \
                       '"text":{"type":"plain_text","text":"Open conversation","emoji":true},' \
                       '"url":"https://qa.chatwoot.com/app/accounts/1/conversations/1",' \
                       '"action_id":"button-action"}]}]}}'
        }

        stub_request(:post, 'https://slack.com/api/chat.unfurl')
          .with(body: expected_body)
          .to_return(status: 200, body: '', headers: {})
        result = link_builder.perform
        expect(result).to eq([{ url: 'https://qa.chatwoot.com/app/accounts/1/conversations/1', domain: 'qa.chatwoot.com' }])
      end
    end

    context 'when the event contains containing multiple links' do
      let(:link_shared_1) do
        {
          team_id: 'TLST3048H',
          api_app_id: 'A012S5UETV4',
          event: link_shared_event.merge(links: [{
                                           url: "https://qa.chatwoot.com/app/accounts/1/conversations/#{conversation.display_id}",
                                           domain: 'qa.chatwoot.com'
                                         },
                                                 {
                                                   url: "https://qa.chatwoot.com/app/accounts/1/conversations/#{conversation.display_id}",
                                                   domain: 'qa.chatwoot.com'
                                                 }]),
          type: 'event_callback',
          event_time: 1_588_623_033
        }
      end
      let(:link_builder) { described_class.new(params: link_shared_1, integration_hook: hook) }

      it('sends multiple POST unfurl request to Slack') do
        expected_body = {
          'source' => 'conversations_history',
          'unfurl_id' => 'C7NQEAE5Q.1695111587.937099.7e240338c6d2053fb49f56808e7c1f619f6ef317c39ebc59fc4af1cc30dce49b',
          'unfurls' => '{"https://qa.chatwoot.com/app/accounts/1/conversations/1":' \
                       '{"blocks":[{' \
                       '"type":"section",' \
                       '"fields":[{' \
                       '"type":"mrkdwn",' \
                       "\"text\":\"*Name:*\\n#{contact.name}\"}," \
                       '{"type":"mrkdwn","text":"*Email:*\\n---"},' \
                       '{"type":"mrkdwn","text":"*Phone:*\\n---"},' \
                       '{"type":"mrkdwn","text":"*Company:*\\n---"},' \
                       "{\"type\":\"mrkdwn\",\"text\":\"*Inbox:*\\n#{channel_email.inbox.name}\"}," \
                       "{\"type\":\"mrkdwn\",\"text\":\"*Inbox Type:*\\n#{channel_email.inbox.channel.name}\"}]}," \
                       '{"type":"actions","elements":[{' \
                       '"type":"button",' \
                       '"text":{"type":"plain_text","text":"Open conversation","emoji":true},' \
                       '"url":"https://qa.chatwoot.com/app/accounts/1/conversations/1",' \
                       '"action_id":"button-action"}]}]}}'
        }
        stub_request(:post, 'https://slack.com/api/chat.unfurl')
          .with(body: expected_body)
          .to_return(status: 200, body: '', headers: {})
        expect { link_builder.perform }.not_to raise_error
      end
    end
  end
end
