module Whatsapp::ZapiHandlers::DeliveryCallback
  include Whatsapp::ZapiHandlers::Helpers

  private

  def process_delivery_callback
    message = inbox.messages.find_by(source_id: processed_params[:messageId])
    return unless message

    external_created_at = processed_params[:momment] / 1000
    if processed_params[:error].present?
      message.update!(status: :failed, external_error: processed_params[:error], external_created_at: external_created_at)
    else
      message.update!(status: :delivered, external_created_at: external_created_at)
    end
  end
end
