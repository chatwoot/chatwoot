class Gupshup::CallbackController < ApplicationController
  def create
    ::Gupshup::IncomingMessageService.new(params: permitted_params).perform

    head :no_content
  end

  private

  def permitted_params
    params.permit(
      :App,
      :Timestamp,
      :Version,
      :Type,
      :Payload,
      :Sender,
      :Context,
      :Channel,
      :Source,
      :Src.Name,
      :Message
    )
  end
end
