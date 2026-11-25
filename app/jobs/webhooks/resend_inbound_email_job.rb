# The webhook carries only metadata; raw.download_url from the receiving API points at the original file, attachments included.
# https://resend.com/docs/api-reference/emails/retrieve-received-email
class Webhooks::ResendInboundEmailJob < ApplicationJob
  queue_as :default

  # html_format=cid keeps inline images out of the response instead of embedding each one as a base64 data URI this job never reads.
  RECEIVED_EMAIL_URL = 'https://api.resend.com/emails/receiving/%<id>s?html_format=cid'.freeze
  # Nobody waits on this job, so a ceiling buys the worker and a failure lets Sidekiq retry it.
  # The download carries the attachments, so it reads for longer than the metadata lookup.
  RESEND_LOOKUP_REQUEST_OPTIONS = { timeout: 15, max_retries: 0 }.freeze
  RESEND_DOWNLOAD_REQUEST_OPTIONS = { timeout: 30, max_retries: 0 }.freeze

  def perform(email_id)
    received = HTTParty.get(
      format(RECEIVED_EMAIL_URL, id: email_id),
      headers: { 'Authorization' => "Bearer #{ENV.fetch('RESEND_INBOUND_API_KEY')}" },
      raise_on: (400..599).to_a,
      **RESEND_LOOKUP_REQUEST_OPTIONS
    )
    raw = HTTParty.get(
      received.parsed_response.dig('raw', 'download_url'),
      raise_on: (400..599).to_a,
      **RESEND_DOWNLOAD_REQUEST_OPTIONS
    )

    # Ignores a message it already stored, so a redelivered webhook does not open a second conversation.
    ActionMailbox::InboundEmail.create_and_extract_message_id!(raw.body)
  end
end
