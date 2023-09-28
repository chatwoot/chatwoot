class Api::V1::Integrations::WebhooksController < ApplicationController
  def create
    builder = Integrations::Slack::IncomingMessageBuilder.new(permitted_params)
    response = builder.perform
    render json: response
  end

  private

  # TODO: Fix me later
  def permitted_params
    params.permit!
  end
end
