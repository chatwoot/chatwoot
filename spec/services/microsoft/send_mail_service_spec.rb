require 'rails_helper'

describe Microsoft::SendMailService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_email, :microsoft_email, account: account, email: 'test@example.com') }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:message) { create(:message, conversation: conversation, message_type: 'outgoing', content: 'Test reply') }

  let(:service) do
    described_class.new(
      channel: channel,
      message: message,
      to_emails: ['recipient@example.com'],
      cc_emails: [],
      bcc_emails: [],
      subject: 'Re: Test Subject',
      html_body: '<p>Test reply</p>',
      text_body: 'Test reply',
      in_reply_to: '<original-id@example.com>',
      references: '<original-id@example.com>'
    )
  end

  let(:graph_token_service) { instance_double(Microsoft::GraphTokenService, access_token: 'test-graph-token') }

  before do
    allow(Microsoft::GraphTokenService).to receive(:new).and_return(graph_token_service)
  end

  describe '#perform' do
    context 'when Graph API returns 202 (success)' do
      before do
        stub_request(:post, 'https://graph.microsoft.com/v1.0/me/sendMail')
          .to_return(status: 202, body: '', headers: {})
      end

      it 'sends the email via Graph API' do
        service.perform

        expect(WebMock).to have_requested(:post, 'https://graph.microsoft.com/v1.0/me/sendMail')
          .with(headers: { 'Authorization' => 'Bearer test-graph-token', 'Content-Type' => 'text/plain' })
      end

      it 'returns a result with a message_id' do
        result = service.perform

        expect(result.success).to be true
        expect(result.message_id).to include(conversation.uuid)
        expect(result.message_id).to include(message.id.to_s)
      end
    end

    context 'when Graph API returns 401' do
      before do
        stub_request(:post, 'https://graph.microsoft.com/v1.0/me/sendMail')
          .to_return(status: 401, body: '', headers: {})
      end

      it 'raises an authentication error' do
        expect { service.perform }.to raise_error(StandardError, /Authentication failed/)
      end
    end

    context 'when Graph API returns 403' do
      before do
        stub_request(:post, 'https://graph.microsoft.com/v1.0/me/sendMail')
          .to_return(status: 403, body: '', headers: {})
      end

      it 'raises a permission error' do
        expect { service.perform }.to raise_error(StandardError, /Mail.Send scope may be missing/)
      end
    end

    context 'when Graph API returns an unexpected error' do
      before do
        stub_request(:post, 'https://graph.microsoft.com/v1.0/me/sendMail')
          .to_return(
            status: 500,
            body: { 'error' => { 'message' => 'Internal server error' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises an error with the API error message' do
        expect { service.perform }.to raise_error(StandardError, /Internal server error/)
      end
    end
  end
end
