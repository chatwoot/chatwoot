class Api::V1::Integrations::WebhooksController < ApplicationController
  def create
    builder = Integrations::Slack::IncomingMessageBuilder.new(permitted_params)
    response = builder.perform
    render json: response
  end

  private

  # TODO: This is a temporary solution to permit all params for slack unfurling job.
  # We should only permit the params that we use. Handle all the params based on events and send it to the respective services.
  def permitted_params
    params.permit!
  end
end
