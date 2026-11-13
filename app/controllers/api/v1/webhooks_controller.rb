class Api::V1::WebhooksController < ApplicationController
  TWITTER_SIGNATURE_HEADER = 'X-Twitter-Webhooks-Signature'.freeze
  TWITTER_CRC_TOKEN_FORMAT = %r{\A[\w.~+/=-]+\z}

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  before_action :verify_twitter_signature!, only: :twitter_events

  def twitter_crc
    return head :bad_request unless params[:crc_token].to_s.match?(TWITTER_CRC_TOKEN_FORMAT)

    render json: { response_token: "sha256=#{twitter_client.generate_crc(params[:crc_token])}" }
  end

  def twitter_events
    twitter_consumer.consume
    head :ok
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    head :ok
  end

  private

  def verify_twitter_signature!
    return if valid_twitter_signature?

    Rails.logger.warn('[TWITTER] Rejected webhook with a missing or invalid signature')
    head :unauthorized
  end

  def valid_twitter_signature?
    secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
    signature = request.headers[TWITTER_SIGNATURE_HEADER].to_s
    return false if secret.blank? || signature.blank?

    expected = "sha256=#{Base64.strict_encode64(OpenSSL::HMAC.digest('SHA256', secret, request.raw_post))}"
    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def twitter_client
    Twitty::Facade.new do |config|
      config.consumer_secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
    end
  end

  def twitter_consumer
    @twitter_consumer ||= ::Webhooks::Twitter.new(ActionController::Parameters.new(request.request_parameters))
  end
end
