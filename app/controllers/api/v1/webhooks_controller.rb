class Api::V1::WebhooksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user

  def twitter_crc
    render json: { response_token: "sha256=#{twitter_client.generate_crc(params[:crc_token])}" }
  end

  def twitter_events
    twitter_consumer.consume
    head :ok
  rescue StandardError => e
    Sentry.capture_exception(e)
    head :ok
  end

  private

  def twitter_client
    Twitty::Facade.new do |config|
      config.consumer_secret = ENV.fetch('TWITTER_CONSUMER_SECRET', nil)
    end
  end

  def twitter_consumer
    @twitter_consumer ||= ::Webhooks::Twitter.new(params)
  end
end
