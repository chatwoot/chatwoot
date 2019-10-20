class Api::V1::WebhooksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  skip_before_action :check_subscription

  before_action :login_from_basic_auth
  def chargebee
    chargebee_consumer.consume
    head :ok
  rescue StandardError => e
    Raven.capture_exception(e)
    head :ok
  end

  private

  def login_from_basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['CHARGEBEE_WEBHOOK_USERNAME'] && password == ENV['CHARGEBEE_WEBHOOK_PASSWORD']
    end
  end

  def chargebee_consumer
    @consumer ||= ::Webhooks::Chargebee.new(params)
  end
end
