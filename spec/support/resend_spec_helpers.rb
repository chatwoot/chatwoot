# frozen_string_literal: true

require 'base64'

# rubocop:disable Metrics/ModuleLength
module ResendSpecHelpers
  # Webhook payload stubs
  def resend_webhook_payload(email_id: 'test_email_123', event_type: 'email.received')
    {
      type: event_type,
      created_at: '2025-01-15T10:00:00Z',
      data: {
        email_id: email_id
      }
    }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def resend_email_data(options = {})
    {
      from: options[:from] || 'sender@example.com',
      to: options[:to] || ['support@chatwoot.test'],
      cc: options[:cc],
      bcc: options[:bcc],
      subject: options[:subject] || 'Test Email Subject',
      text: options[:text] || 'This is a plain text email body.',
      html: options[:html] || '<p>This is an <strong>HTML</strong> email body.</p>',
      message_id: options[:message_id] || '<message-123@example.com>',
      headers: options[:headers] || {},
      attachments: options[:attachments] || []
    }
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def resend_email_with_attachments
    resend_email_data(
      attachments: [
        {
          id: 'att_regular_123',
          filename: 'document.pdf',
          content_type: 'application/pdf',
          content_disposition: 'attachment'
        },
        {
          id: 'att_inline_456',
          filename: 'image.png',
          content_type: 'image/png',
          content_disposition: 'inline',
          content_id: '<image123>'
        }
      ]
    )
  end

  def resend_email_with_inline_images
    resend_email_data(
      # rubocop:disable Layout/LineLength
      html: '<p>Email with image: <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==" /></p>',
      # rubocop:enable Layout/LineLength
      attachments: [
        {
          id: 'att_inline_123',
          filename: 'inline.png',
          content_type: 'image/png',
          content_disposition: 'inline',
          content_id: '<inline123>'
        }
      ]
    )
  end

  def resend_attachment_metadata(attachment_id: 'att_123', download_url: nil)
    {
      id: attachment_id,
      filename: 'test_file.pdf',
      content_type: 'application/pdf',
      size: 1024,
      download_url: download_url || "https://cdn.resend.app/inbound/test-email-123/attachments/#{attachment_id}?signature=test-sig"
    }
  end

  # Sample attachment content (1x1 transparent PNG)
  def sample_attachment_content
    Base64.strict_decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==')
  end

  # Svix signature headers
  def svix_headers(_payload_json: nil, valid: true)
    if valid
      {
        'svix-id' => 'msg_test_123',
        'svix-timestamp' => Time.now.to_i.to_s,
        'svix-signature' => 'v1,valid_signature_here'
      }
    else
      {
        'svix-id' => 'msg_invalid',
        'svix-timestamp' => (Time.now.to_i - 10_000).to_s, # Old timestamp
        'svix-signature' => 'v1,invalid_signature'
      }
    end
  end

  # WebMock stubs
  def stub_resend_email_fetch(email_id: 'test_email_123', response_body: nil, status: 200)
    response_body ||= resend_email_data.to_json

    stub_request(:get, "https://api.resend.com/emails/receiving/#{email_id}")
      .with(headers: { 'Authorization' => /Bearer .+/ })
      .to_return(
        status: status,
        body: response_body,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_resend_attachment_metadata_fetch(email_id:, attachment_id:, download_url: nil, status: 200)
    download_url ||= "https://cdn.resend.app/inbound/#{email_id}/attachments/#{attachment_id}"
    metadata = resend_attachment_metadata(attachment_id: attachment_id, download_url: download_url)

    stub_request(:get, "https://api.resend.com/emails/receiving/#{email_id}/attachments/#{attachment_id}")
      .with(headers: { 'Authorization' => /Bearer .+/ })
      .to_return(
        status: status,
        body: metadata.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_resend_attachment_download(download_url:, content: nil, status: 200)
    content ||= sample_attachment_content

    # Stub HEAD request for size check
    stub_request(:head, download_url)
      .to_return(
        status: 200,
        headers: { 'Content-Length' => content.bytesize.to_s }
      )

    # Stub GET request for actual download
    stub_request(:get, download_url)
      .to_return(
        status: status,
        body: content,
        headers: { 'Content-Type' => 'application/octet-stream' }
      )
  end

  def stub_all_resend_apis(email_id: 'test_email_123', email_data: nil)
    email_data ||= resend_email_data

    # Stub email fetch
    stub_resend_email_fetch(email_id: email_id, response_body: email_data.to_json)

    # Stub attachment fetches if email has attachments
    return if email_data[:attachments].blank?

    email_data[:attachments].each do |attachment|
      download_url = "https://cdn.resend.app/inbound/#{email_id}/attachments/#{attachment[:id]}?signature=test-sig"

      # Stub attachment metadata
      stub_resend_attachment_metadata_fetch(
        email_id: email_id,
        attachment_id: attachment[:id],
        download_url: download_url
      )

      # Stub attachment download
      stub_resend_attachment_download(download_url: download_url)
    end
  end

  # Svix verification mocking
  def mock_svix_verification(valid: true)
    svix_webhook = instance_double(Svix::Webhook)
    allow(Svix::Webhook).to receive(:new).and_return(svix_webhook)

    if valid
      allow(svix_webhook).to receive(:verify).and_return(true)
    else
      allow(svix_webhook).to receive(:verify).and_raise(Svix::WebhookVerificationError.new('Invalid signature'))
    end

    svix_webhook
  end

  # Environment variable setup
  def setup_resend_env_vars
    ENV['RESEND_API_KEY'] = 'test_api_key_123'
    ENV['RESEND_WEBHOOK_SECRET'] = 'test_webhook_secret_123'
  end

  def clear_resend_env_vars
    ENV.delete('RESEND_API_KEY')
    ENV.delete('RESEND_WEBHOOK_SECRET')
  end
end
# rubocop:enable Metrics/ModuleLength
