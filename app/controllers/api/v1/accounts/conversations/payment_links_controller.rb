class Api::V1::Accounts::Conversations::PaymentLinksController < Api::V1::Accounts::Conversations::BaseController
  skip_before_action :conversation
  before_action :set_conversation

  def create
    payment_link = PaymentLinks::CreateService.new(
      conversation: @conversation,
      user: Current.user,
      amount: permitted_params[:amount],
      currency: permitted_params[:currency],
      provider: permitted_params[:provider]
    ).perform

    render json: { success: true, data: payment_link_response(payment_link) }, status: :created
  rescue StandardError => e
    Rails.logger.error "Payment link generation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def payment_link_response(payment_link)
    {
      payment_url: payment_link.payment_url,
      external_payment_id: payment_link.external_payment_id,
      amount: payment_link.amount,
      currency: payment_link.currency,
      provider: payment_link.provider
    }
  end

  def permitted_params
    params.permit(:amount, :currency, :provider)
  end

  def set_conversation
    @conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    authorize PaymentLink, :create?
  end
end
