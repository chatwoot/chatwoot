# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActionMailbox::Ingresses::Resend::InboundEmailsController, type: :controller do
  include ResendSpecHelpers

  before do
    setup_resend_env_vars
  end

  after do
    clear_resend_env_vars
  end

  describe 'POST #create' do
    let(:email_id) { 'test_email_123' }
    let(:webhook_payload) { resend_webhook_payload(email_id: email_id) }
    let(:email_data) { resend_email_data }

    context 'with valid webhook and signature' do
      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_data)
      end

      it 'returns 200 OK' do
        request.headers.merge!(svix_headers(valid: true))
        post :create, body: webhook_payload.to_json

        expect(response).to have_http_status(:ok)
      end

      it 'creates an ActionMailbox inbound email' do
        request.headers.merge!(svix_headers(valid: true))

        expect do
          post :create, body: webhook_payload.to_json
        end.to change(ActionMailbox::InboundEmail, :count).by(1)
      end

      it 'processes the webhook with correct email data' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_including('From: sender@example.com')
        )

        post :create, body: webhook_payload.to_json
      end

      it 'includes subject in RFC822 message' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_including('Subject: Test Email Subject')
        )

        post :create, body: webhook_payload.to_json
      end

      it 'includes text body in RFC822 message' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_including('This is a plain text email body.')
        )

        post :create, body: webhook_payload.to_json
      end

      it 'includes HTML body in RFC822 message' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_including('<p>This is an <strong>HTML</strong> email body.</p>')
        )

        post :create, body: webhook_payload.to_json
      end
    end

    context 'with invalid signature' do
      before do
        mock_svix_verification(valid: false)
      end

      it 'returns 401 unauthorized' do
        request.headers.merge!(svix_headers(valid: false))
        post :create, body: webhook_payload.to_json

        expect(response).to have_http_status(:unauthorized)
      end

      it 'does not create an inbound email' do
        request.headers.merge!(svix_headers(valid: false))

        expect do
          post :create, body: webhook_payload.to_json
        end.not_to change(ActionMailbox::InboundEmail, :count)
      end

      it 'does not call ActionMailbox' do
        request.headers.merge!(svix_headers(valid: false))

        expect(ActionMailbox::InboundEmail).not_to receive(:create_and_extract_message_id!)

        post :create, body: webhook_payload.to_json
      end
    end

    context 'with missing signature headers' do
      before do
        mock_svix_verification(valid: false)
      end

      it 'returns 401 unauthorized when svix-signature is missing' do
        request.headers.merge!(svix_headers(valid: true).except('svix-signature'))
        post :create, body: webhook_payload.to_json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with stale timestamp' do
      before do
        mock_svix_verification(valid: false)
      end

      it 'rejects webhook with old timestamp' do
        old_headers = svix_headers(valid: true)
        old_headers['svix-timestamp'] = (Time.now.to_i - 10_000).to_s

        request.headers.merge!(old_headers)
        post :create, body: webhook_payload.to_json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with non-email.received event type' do
      let(:other_event_payload) { resend_webhook_payload(email_id: email_id, event_type: 'email.sent') }

      before do
        mock_svix_verification(valid: true)
      end

      it 'returns 200 OK but does not process' do
        request.headers.merge!(svix_headers(valid: true))
        post :create, body: other_event_payload.to_json

        expect(response).to have_http_status(:ok)
      end

      it 'does not create an inbound email' do
        request.headers.merge!(svix_headers(valid: true))

        expect do
          post :create, body: other_event_payload.to_json
        end.not_to change(ActionMailbox::InboundEmail, :count)
      end
    end

    context 'with missing email_id' do
      let(:invalid_payload) { resend_webhook_payload(email_id: nil).tap { |p| p[:data].delete(:email_id) } }

      before do
        mock_svix_verification(valid: true)
      end

      it 'returns 422 unprocessable entity' do
        request.headers.merge!(svix_headers(valid: true))
        post :create, body: invalid_payload.to_json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid JSON payload' do
      before do
        mock_svix_verification(valid: true)
      end

      it 'returns 400 bad request' do
        request.headers.merge!(svix_headers(valid: true))
        post :create, body: 'invalid json{'

        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'when Resend API fails' do
      before do
        mock_svix_verification(valid: true)
        stub_resend_email_fetch(email_id: email_id, status: 500)
      end

      it 'returns 500 internal server error' do
        request.headers.merge!(svix_headers(valid: true))
        post :create, body: webhook_payload.to_json

        expect(response).to have_http_status(:internal_server_error)
      end

      it 'does not create an inbound email' do
        request.headers.merge!(svix_headers(valid: true))

        expect do
          post :create, body: webhook_payload.to_json
        end.not_to change(ActionMailbox::InboundEmail, :count)
      end
    end

    context 'with attachments' do
      let(:email_with_attachments) { resend_email_with_attachments }

      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_with_attachments)
      end

      it 'fetches and includes attachments in RFC822 message' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(%r{Content-Type: application/pdf})
        )

        post :create, body: webhook_payload.to_json
      end

      it 'handles inline attachments with Content-Disposition' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/Content-Disposition: inline/)
        )

        post :create, body: webhook_payload.to_json
      end

      it 'sets Content-ID for inline images' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/Content-ID:/)
        )

        post :create, body: webhook_payload.to_json
      end
    end

    context 'with inline images (data URI conversion)' do
      let(:email_with_inline_images) { resend_email_with_inline_images }

      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_with_inline_images)
      end

      it 'converts data URI images to cid: references' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/cid:inline123/)
        )

        post :create, body: webhook_payload.to_json
      end

      it 'does not include data URI in final message' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(%r{^(?!.*data:image/png;base64).*$}m)
        )

        post :create, body: webhook_payload.to_json
      end
    end

    context 'when verifying RFC822 message structure' do
      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_data)
      end

      it 'builds proper MIME-Version header' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/Mime-Version: 1\.0/i)
        )

        post :create, body: webhook_payload.to_json
      end

      it 'creates multipart/alternative for text + HTML' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(%r{Content-Type: multipart/alternative})
        )

        post :create, body: webhook_payload.to_json
      end
    end

    context 'with threading headers' do
      let(:email_with_threading) do
        resend_email_data(
          message_id: '<message-456@example.com>',
          headers: {
            'in-reply-to' => '<message-123@example.com>',
            'references' => '<message-123@example.com> <message-456@example.com>'
          }
        )
      end

      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_with_threading)
      end

      it 'includes In-Reply-To header' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/In-Reply-To: <message-123@example\.com>/)
        )

        post :create, body: webhook_payload.to_json
      end

      it 'includes References header' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/References:/)
        )

        post :create, body: webhook_payload.to_json
      end
    end

    context 'when RESEND_API_KEY is not configured' do
      before do
        ENV.delete('RESEND_API_KEY')
        mock_svix_verification(valid: true)
      end

      it 'returns 500 internal server error' do
        request.headers.merge!(svix_headers(valid: true))
        post :create, body: webhook_payload.to_json

        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'when RESEND_WEBHOOK_SECRET is not configured' do
      before do
        ENV.delete('RESEND_WEBHOOK_SECRET')
      end

      it 'returns 401 unauthorized' do
        request.headers.merge!(svix_headers(valid: true))
        post :create, body: webhook_payload.to_json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with CC and BCC recipients' do
      let(:email_with_cc_bcc) do
        resend_email_data(
          cc: ['cc@example.com'],
          bcc: ['bcc@example.com']
        )
      end

      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_with_cc_bcc)
      end

      it 'includes CC header' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/Cc: cc@example\.com/)
        )

        post :create, body: webhook_payload.to_json
      end

      it 'does not include BCC header in RFC822 message' do
        request.headers.merge!(svix_headers(valid: true))

        # BCC headers should NOT appear in the final RFC822 message per RFC 5322
        # The Mail gem correctly strips BCC to maintain the "blind" nature of blind carbon copy
        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(/^(?!.*Bcc:).*$/m)
        )

        post :create, body: webhook_payload.to_json
      end
    end

    context 'with only HTML body (no text)' do
      let(:email_html_only) do
        resend_email_data(
          text: nil,
          html: '<h1>HTML Only</h1>'
        )
      end

      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_html_only)
      end

      it 'creates RFC822 with HTML content type' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(%r{Content-Type: text/html})
        )

        post :create, body: webhook_payload.to_json
      end
    end

    context 'with only text body (no HTML)' do
      let(:email_text_only) do
        resend_email_data(
          text: 'Plain text only',
          html: nil
        )
      end

      before do
        mock_svix_verification(valid: true)
        stub_all_resend_apis(email_id: email_id, email_data: email_text_only)
      end

      it 'creates RFC822 with text/plain content type' do
        request.headers.merge!(svix_headers(valid: true))

        expect(ActionMailbox::InboundEmail).to receive(:create_and_extract_message_id!).with(
          a_string_matching(%r{Content-Type: text/plain})
        )

        post :create, body: webhook_payload.to_json
      end
    end
  end
end
