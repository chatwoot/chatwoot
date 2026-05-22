# Fire-and-forget fan-out: forwards the raw Meta Instagram webhook payload
# (body + x-hub-signature-256 byte-for-byte) to the Socialwise receptor.
# Socialwise revalidates HMAC with INSTAGRAM_APP_SECRET as if the request had
# come from Meta directly — the App and the secret are the same on both sides.

require 'httparty'

class Webhooks::InstagramSocialwiseForwarderJob < ApplicationJob
  queue_as :low

  retry_on(
    Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH,
    Net::OpenTimeout, Net::ReadTimeout, HTTParty::Error,
    wait: :exponentially_longer, attempts: 5
  )

  USER_AGENT = 'Chatwit-IG-Forwarder/1.0'.freeze
  OPEN_TIMEOUT_S = 3
  READ_TIMEOUT_S = 8

  def perform(raw_body:, signature:)
    target = ENV.fetch('SOCIALWISE_INSTAGRAM_WEBHOOK_URL', '').to_s
    if target.empty?
      Rails.logger.info('[IG-FORWARD] skipped — SOCIALWISE_INSTAGRAM_WEBHOOK_URL not set')
      return
    end

    response = HTTParty.post(
      target,
      body: raw_body.to_s,
      headers: {
        'Content-Type' => 'application/json',
        'X-Hub-Signature-256' => signature.to_s,
        'User-Agent' => USER_AGENT
      },
      open_timeout: OPEN_TIMEOUT_S,
      timeout: READ_TIMEOUT_S
    )

    if response.success?
      Rails.logger.info("[IG-FORWARD] ok status=#{response.code}")
      return
    end

    # 403 = signature mismatch on the Socialwise side. Retrying won't fix env
    # divergence — log loudly and stop so a bad payload doesn't tie up the queue.
    if response.code.to_i == 403
      Rails.logger.error(
        '[IG-FORWARD] 403 signature mismatch — verify INSTAGRAM_APP_SECRET parity ' \
        "between Meta App and socialwise-frontend env. body=#{response.body.to_s[0, 200]}"
      )
      return
    end

    Rails.logger.error(
      "[IG-FORWARD] non-2xx status=#{response.code} body=#{response.body.to_s[0, 500]}"
    )
    raise "Socialwise forwarder non-2xx: #{response.code}"
  end
end
