class Webhooks::InstagramController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user

  def verify
    if valid_instagram_token?(params['hub.verify_token'])
      Rails.logger.info('Instagram webhook verified')
      render json: params['hub.challenge']
    else
      render json: { error: 'Error; wrong verify token', status: 403 }
    end
  end

  def events
    Rails.logger.info('Instagram webhook received events')
    if params['object'].casecmp('instagram').zero?
      ::Webhooks::InstagramEventsJob.perform_later(params.to_unsafe_hash[:entry])
      render json: :ok
    else
      Rails.logger.info("Message is not received from the instagram webhook event: #{params['object']}")
      head :unprocessable_entity
    end
  end

  private

  def valid_instagram_token?(token)
    token == ENV['IG_VERIFY_TOKEN']
  end
end
