class Api::V1::Accounts::Conversations::CatalogItemsController < Api::V1::Accounts::Conversations::BaseController
  def create
    message = Catalog::SendItemsService.new(
      conversation: @conversation,
      product_ids: permitted_params[:product_ids],
      user: Current.user
    ).perform

    render json: {
      success: true,
      message_id: message.id
    }, status: :created
  rescue StandardError => e
    Rails.logger.error "Catalog items send failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def permitted_params
    params.permit(product_ids: [])
  end
end
