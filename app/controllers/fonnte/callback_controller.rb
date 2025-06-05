class Fonnte::CallbackController < ApplicationController
  # include MetaTokenVerifyConcern
  # skip_before_action :verify_authenticity_token
  # before_action :verify_meta_token

  def create
    Fonnte::IncomingMessageService.new(params: permitted_params).perform
    head :ok
  end

  private

  def permitted_params
    params.permit(
      :token,
      :phone_number,
      :message,
      :timestamp,
      :url,
      :type,
      :token
    )
  end
end
