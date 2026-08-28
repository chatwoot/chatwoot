class Api::V1::Integrations::WebhooksController < ApplicationController
  SIGNATURE_TOLERANCE = 5.minutes.to_i

  prepend_before_action :verify_slack_signature!, only: [:create]

  def create
    builder = Integrations::Slack::IncomingMessageBuilder.new(permitted_params)
    response = builder.perform
    render json: response
  end

  private

  # Skip (rather than reject) when no secret is configured, so existing installs keep working.
  def verify_slack_signature!
    secret = slack_signing_secret
    if secret.blank?
      Rails.logger.warn('[SLACK] SLACK_SIGNING_SECRET not configured; skipping webhook signature verification')
      return
    end

    head :unauthorized unless valid_slack_signature?(secret)
  end

  # Config reconciliation creates a blank row for this key on upgrade, and that blank row
  # makes GlobalConfigService skip its ENV fallback, so read ENV directly as a last resort.
  def slack_signing_secret
    GlobalConfigService.load('SLACK_SIGNING_SECRET', nil).presence || ENV.fetch('SLACK_SIGNING_SECRET', nil)
  end

  def valid_slack_signature?(secret)
    timestamp = request.headers['X-Slack-Request-Timestamp']
    signature = request.headers['X-Slack-Signature']
    return false if timestamp.blank? || signature.blank?
    return false if (Time.current.to_i - timestamp.to_i).abs > SIGNATURE_TOLERANCE

    # Build over raw bytes so a payload with invalid UTF-8 can't raise on interpolation.
    basestring = "v0:#{timestamp}:".b << request.raw_post
    expected = "v0=#{OpenSSL::HMAC.hexdigest('SHA256', secret, basestring)}"
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  # TODO: This is a temporary solution to permit all params for slack unfurling job.
  # We should only permit the params that we use. Handle all the params based on events and send it to the respective services.
  def permitted_params
    params.permit!
  end
end
