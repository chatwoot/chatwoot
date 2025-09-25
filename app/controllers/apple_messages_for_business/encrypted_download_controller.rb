class AppleMessagesForBusiness::EncryptedDownloadController < ApplicationController
  before_action :validate_download_token
  before_action :find_attachment

  def show
    cipher_service = AppleMessagesForBusiness::AttachmentCipherService.new(@channel)

    result = cipher_service.decrypt_attachment(@attachment)

    if result[:success]
      send_data result[:content],
                filename: result[:filename],
                type: result[:content_type],
                disposition: 'attachment'
    else
      render json: { error: result[:error] }, status: :not_found
    end
  end

  private

  def validate_download_token
    token = params[:token]
    return render_error('Missing download token') unless token

    cipher_service = AppleMessagesForBusiness::AttachmentCipherService.new
    token_validation = cipher_service.validate_download_token(token)

    unless token_validation[:valid]
      return render_error(token_validation[:error])
    end

    @attachment = token_validation[:attachment]
    @channel = Channel::AppleMessagesForBusiness.find(token_validation[:channel_id]) if token_validation[:channel_id]
  end

  def find_attachment
    return render_error('Attachment not found') unless @attachment
    return render_error('Attachment not encrypted') unless @attachment.encrypted?
  end

  def render_error(error_message)
    render json: { error: error_message }, status: :unauthorized
  end
end