require 'rails_helper'

describe Integrations::Slack::LinkUnfurlHelper do
  describe '#generate_unfurls' do
    let(:link_unfurl_helper) { Object.new.extend(described_class) }

    context 'when valid user info and url provided' do
      user_info = {
        user_name: 'Candice Matherson',
        email: 'candice@example.com',
        phone_number: '974237862323',
        company_name: 'Chatwoot'
      }

      url = 'https://example.com/app/accounts/1/conversations/100'

      expected_payload = { 'https://example.com/app/accounts/1/conversations/100' => {
        'blocks' => [
          {
            'type' => 'section',
            'fields' => [
              {
                'type' => 'mrkdwn',
                'text' => "*Name:*\nCandice Matherson"
              },
              {
                'type' => 'mrkdwn',
                'text' => "*Email:*\ncandice@example.com"
              },
              {
                'type' => 'mrkdwn',
                'text' => "*Phone:*\n974237862323"
              },
              {
                'type' => 'mrkdwn',
                'text' => "*Company:*\nChatwoot"
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
                'url' => url,
                'action_id' => 'button-action'
              }
            ]
          }
        ]
      } }

      it 'returns the expected payload' do
        payload = link_unfurl_helper.generate_unfurls(url, user_info)
        expect(payload).to eq(expected_payload)
      end
    end
  end
end
