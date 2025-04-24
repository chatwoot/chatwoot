class Api::V1::Bot::AttachmentsController < Api::V1::Accounts::BaseController
  # POST /api/v1/bot/attachments
  # Tạo attachment mới với file upload
  def create
    @attachment = Current.account.attachments.new(attachment_params)
    @attachment.save!
    
    render json: @attachment
  end

  # POST /api/v1/bot/attachments/external
  # Tạo attachment mới với external URL
  def external
    @attachment = Current.account.attachments.new(
      external_url: params[:external_url],
      file_type: params[:file_type] || :image
    )
    @attachment.save!
    
    render json: @attachment
  end

  private

  def attachment_params
    params.permit(:file, :file_type, :external_url)
  end
end
