class Api::V1::Accounts::Conversations::AttachmentsController < Api::V1::Accounts::Conversations::BaseController
  before_action :set_message
  before_action :set_attachment
  before_action :validate_meta_size, only: [:update]

  MAX_META_SIZE = 16.kilobytes

  def update
    @attachment.update!(permitted_params)
    @attachment.message.send_update_event
  end

  private

  def set_message
    @message = @conversation.messages.find(params[:message_id])
  end

  def set_attachment
    @attachment = @message.attachments.find(params[:id])
  end

  def permitted_params
    params.permit(meta: {})
  end

  def validate_meta_size
    return if params[:meta].blank?

    return unless params[:meta].to_json.bytesize > MAX_META_SIZE

    render json: { error: "Metadata size exceeds maximum allowed (#{MAX_META_SIZE / 1024}KB)" }, status: :unprocessable_entity
  end
end
