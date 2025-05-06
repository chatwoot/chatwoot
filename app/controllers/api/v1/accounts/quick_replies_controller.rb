class Api::V1::Accounts::QuickRepliesController < Api::V1::Accounts::BaseController
  before_action :set_quick_reply, only: [:update, :destroy]

  def index
    @quick_replies = if params[:search].present?
                       Current.account.quick_replies.where(
                         'name ILIKE :query OR content ILIKE :query',
                         query: "%#{params[:search]}%"
                       )
                     else
                       Current.account.quick_replies
                     end

    render json: @quick_replies
  end

  def create
    @quick_reply = Current.account.quick_replies.new(quick_reply_params)
    if @quick_reply.save
      render json: @quick_reply, status: :created
    else
      render json: { errors: @quick_reply.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @quick_reply.update(quick_reply_params)
      render json: @quick_reply
    else
      render json: { errors: @quick_reply.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @quick_reply.destroy
    head :ok
  end

  private

  def set_quick_reply
    @quick_reply = Current.account.quick_replies.find(params[:id])
  end

  def quick_reply_params
    params.require(:quick_reply).permit(:name, :content)
  end
end
