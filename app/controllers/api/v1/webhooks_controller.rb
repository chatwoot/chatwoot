class Api::V1::WebhooksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  skip_before_action :check_subscription

  before_action :login_from_basic_auth, only: [:chargebee]
  before_action :check_billing_enabled, only: [:chargebee]

  def chargebee
    chargebee_consumer.consume
    head :ok
  rescue StandardError => e
    Raven.capture_exception(e)
    head :ok
  end

  def twitter_crc
    render json: { response_token: "sha256=#{twitter_client.generate_crc(params[:crc_token])}" }
  end

  def twitter_events
    twitter_consumer.consume
    head :ok
  rescue StandardError => e
    Raven.capture_exception(e)
    head :ok
  end

  private

  def twitter_client
    Twitty::Facade.new do |config|
      config.consumer_secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
    end
  end

  def login_from_basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['CHARGEBEE_WEBHOOK_USERNAME'] && password == ENV['CHARGEBEE_WEBHOOK_PASSWORD']
    end
  end

  def chargebee_consumer
    @chargebee_consumer ||= ::Webhooks::Chargebee.new(params)
  end

  def twitter_consumer
    @twitter_consumer ||= ::Webhooks::Twitter.new(params)
  end
end
