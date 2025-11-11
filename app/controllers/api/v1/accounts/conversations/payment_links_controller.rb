class Api::V1::Accounts::Conversations::PaymentLinksController < Api::V1::Accounts::Conversations::BaseController
  def create
    payment_link_data = generate_payment_link
    send_payment_link_message(payment_link_data)

    render json: {
      success: true,
      data: {
        payment_url: payment_link_data[:payment_url],
        payment_id: payment_link_data[:payment_id],
        direct_url: payment_link_data[:direct_url],
        gateway_url: payment_link_data[:gateway_url],
        amount: permitted_params[:amount],
        currency: permitted_params[:currency]
      }
    }, status: :created
  rescue StandardError => e
    Rails.logger.error "Payment link generation failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def generate_payment_link
    service = Payzah::CreatePaymentLinkService.new(
      trackid: generate_track_id,
      amount: permitted_params[:amount],
      currency: permitted_params[:currency],
      customer: customer_data
    )

    service.perform
  end

  def send_payment_link_message(payment_link_data)
    message_params = {
      content: format_payment_link_message(payment_link_data),
      message_type: :outgoing,
      private: false
    }

    Messages::MessageBuilder.new(Current.user, @conversation, message_params).perform
  end

  def format_payment_link_message(payment_link_data)
    <<~MESSAGE
      Amount: #{permitted_params[:amount]} #{permitted_params[:currency]}

      Click here to pay: #{payment_link_data[:payment_url]}
    MESSAGE
  end

  def generate_track_id
    @conversation.display_id
  end

  def customer_data
    contact = @conversation.contact

    {
      name: permitted_params.dig(:customer, :name).presence || contact&.name,
      email: permitted_params.dig(:customer, :email).presence || contact&.email,
      phone: permitted_params.dig(:customer, :phone).presence || contact&.phone_number
    }.compact
  end

  def permitted_params
    params.permit(:amount, :currency, customer: [:name, :email, :phone])
  end
end
