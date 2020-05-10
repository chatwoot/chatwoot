class Api::V1::Integrations::WebhooksController < ApplicationController
  def create
      if params[:type] == "url_verification"
      render json: { challenge: params[:challenge]} 
    else
      head :ok
    end
  end
end
