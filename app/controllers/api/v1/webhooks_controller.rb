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

  def instagram_verify
    if valid_instagram_token?(params['hub.verify_token'])
      Rails.logger.info('Instagram webhook verified')
      render json: params['hub.challenge']
    else
      render json: { error: 'Error; wrong verify token', status: 403 }
    end
  end

  def instagram_events
    Rails.logger.info('Instagram webhook received events')
    if params['object'].casecmp('instagram').zero?
      instagram_consumer.consume
      render json: :ok
    else
      Rails.logger.info("Message is not received from the instagram webhook event: #{params['object']}")
      head :unprocessable_entity
    end
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

  def instagram_consumer
    @messenger_account ||= ::Webhooks::Instagram.new(params[:entry])
  end

  def valid_instagram_token?(token)
    token == ENV['IG_VERIFY_TOKEN']
  end
end
