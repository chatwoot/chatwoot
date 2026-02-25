require 'rails_helper'

describe Integrations::Slack::LinkUnfurlFormatter do
  let(:contact) { create(:contact) }
  let(:inbox) { create(:inbox) }
  let(:url) { 'https://example.com/app/accounts/1/conversations/100' }

  describe '#perform' do
    context 'when unfurling a URL' do
      let(:user_info) do
        {
          user_name: contact.name,
          email: contact.email,
          phone_number: '---',
          company_name: '---'
        }
      end

      let(:expected_payload) do
        {
          url => {
            'blocks' => [
              {
                'type' => 'section',
                'fields' => [
                  { 'type' => 'mrkdwn', 'text' => "*Name:*\n#{contact.name}" },
                  { 'type' => 'mrkdwn', 'text' => "*Email:*\n#{contact.email}" },
                  { 'type' => 'mrkdwn', 'text' => "*Phone:*\n---" },
                  { 'type' => 'mrkdwn', 'text' => "*Company:*\n---" },
                  { 'type' => 'mrkdwn', 'text' => "*Inbox:*\n#{inbox.name}" },
                  { 'type' => 'mrkdwn', 'text' => "*Inbox Type:*\n#{inbox.channel_type}" }
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

      it 'returns expected unfurl blocks when the URL is not blank' do
        formatter = described_class.new(url: url, user_info: user_info, inbox_name: inbox.name, inbox_type: inbox.channel_type)
        expect(formatter.perform).to eq(expected_payload)
      end

      it 'returns an empty hash when the URL is blank' do
        formatter = described_class.new(url: nil, user_info: user_info, inbox_name: inbox.name, inbox_type: inbox.channel_type)
        expect(formatter.perform).to eq({})
      end
    end
  end
end
