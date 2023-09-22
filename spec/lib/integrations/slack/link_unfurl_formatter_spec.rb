require 'rails_helper'

describe Integrations::Slack::LinkUnfurlFormatter do
  describe '#perform' do
    let(:user_info) do
      {
        user_name: 'Candice Matherson',
        email: 'candice@example.com',
        phone_number: '974237862323',
        company_name: 'Chatwoot'
      }
    end

    let(:url) { 'https://example.com/app/accounts/1/conversations/100' }

    let(:expected_payload) do
      {
        url => {
          'blocks' => [
            {
              'type' => 'section',
              'fields' => [
                { 'type' => 'mrkdwn', 'text' => "*Name:*\nCandice Matherson" },
                { 'type' => 'mrkdwn', 'text' => "*Email:*\ncandice@example.com" },
                { 'type' => 'mrkdwn', 'text' => "*Phone:*\n974237862323" },
                { 'type' => 'mrkdwn', 'text' => "*Company:*\nChatwoot" }
              ]
            },
            {
              'type' => 'actions',
              'elements' => [
                {
                  'type' => 'button',
                  'text' => { 'type' => 'plain_text', 'text' => 'Open conversation', 'emoji' => true },
                  'url' => url,
                  'action_id' => 'button-action'
                }
              ]
            }
          ]
        }
      }
    end

    context 'when unrfurl calls' do
      it 'return unfurl blocks when the URL is not blank' do
        formatter = described_class.new(url: url, user_info: user_info)
        expect(formatter.perform).to eq(expected_payload)
      end

      it 'reutrn empty hash when the URL is blank' do
        formatter = described_class.new(url: nil, user_info: user_info)
        expect(formatter.perform).to eq({})
      end
    end
  end
end
