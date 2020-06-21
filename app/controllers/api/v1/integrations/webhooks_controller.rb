class Api::V1::Integrations::WebhooksController < ApplicationController
  def create
    builder = Integrations::Slack::IncomingMessageBuilder.new(params)
    response = builder.perform
    render json: response
  end
end
