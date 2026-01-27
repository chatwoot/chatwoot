class Api::V1::Accounts::ReusableAttachmentsController < Api::V1::Accounts::BaseController
  before_action :set_reusable_attachment, only: [:show, :update, :destroy]

  def index
    @reusable_attachments = Current.account.reusable_attachments.order(created_at: :desc)
  end

  def show; end

  def create
    @reusable_attachment = Current.account.reusable_attachments.new(reusable_attachment_params)

    if @reusable_attachment.save
      render json: @reusable_attachment.as_json, status: :created
    else
      render json: { errors: @reusable_attachment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @reusable_attachment.update(reusable_attachment_params)
      render json: @reusable_attachment.as_json
    else
      render json: { errors: @reusable_attachment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @reusable_attachment.destroy
    head :no_content
  end

  private

  def set_reusable_attachment
    @reusable_attachment = Current.account.reusable_attachments.find(params[:id])
  end

  def reusable_attachment_params
    params.require(:reusable_attachment).permit(:name, :description, :file)
  end
end
