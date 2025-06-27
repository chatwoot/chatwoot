class Api::V2::Accounts::Shopify::OrdersController < Api::V1::Accounts::BaseController
  before_action :setup_shopify_context, only: [:show, :cancel_order, :calculate_refund, :refund_order]
  before_action :fetch_order, only: [:show, :cancel_order, :calculate_refund, :refund_order]

  # Define the mutation as a constant
  # ORDER_CANCEL_MUTATION = <<~GRAPHQL
  #   mutation($input: input) {
  #     orderCancel(input: $input) {
  #       job {
  #         id
  #         status
  #       }
  #       orderCancelUserErrors {
  #         field
  #         message
  #       }
  #     }
  #   }
  # GRAPHQL

  ORDER_CANCEL_MUTATION = <<~GRAPHQL
    mutation orderCancel($notifyCustomer: Boolean, $orderId: ID!, $reason: OrderCancelReason!, $refund: Boolean!, $restock: Boolean!, $staffNote: String) {
      orderCancel(notifyCustomer: $notifyCustomer, orderId: $orderId, reason: $reason, refund: $refund, restock: $restock, staffNote: $staffNote) {
        job {
          id
        }
        orderCancelUserErrors {
          field
          message
        }
      }
    }
  GRAPHQL

  def show
  end

  def fetch_order
    @order = Order.find(params[:id])
  end

  def setup_shopify_context
    @shopify_service = Shopify::ClientService.new(Current.account.id)
  end

  def cancel_order
    permitted = params.permit(:reason, :refund, :restock, :notify_customer)

    Current.user.pubsub_token
    # Prepare the input variables
    orderGid =  "gid://shopify/Order/#{@order.id}"

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        ORDER_CANCEL_MUTATION,
        orderId:   orderGid,
        reason:   permitted[:reason],
        refund:  permitted[:refund],
        restock:   permitted[:restock],
        notifyCustomer:  permitted[:notify_customer],
        staffNote: "Cancelled via api" # TODO: Make this field on frontend
      )

      # Handle the response
      job = response.data.orderCancel.job # job => {id}
      errors = response.data.orderCancel.orderCancelUserErrors

      if errors.any?
        render json: {errors: errors.map(&:to_h)}, status: :unprocessable_entity
      else
        Shopify::OrderCancellationPollingJob.perform_later({
          id: job.id,
          order_id: @order.id,
          user_token: Current.user.pubsub_token(),
          shop: @shopify_service.shop
        })

        render json: {message: I18n.t('shopify.order_cancellation_process') }
      end
    end
  end

  def refund_order
    permitted = params.permit(:note, :notify, :currency, refund_line_items: [:line_item_id, :quantity, :restock_type], transactions: [:parent_id, :amount,:kind, :gateway ], shipping: [:amount, :tax, :maximum_refundable])

    refund_line_items, transactions, note, notify, currency, shipping = permitted.values_at(:refund_line_items, :transactions, :note, :notify, :currency, :shipping)

    payload = {
      refund: {
        currency: currency,
        shipping: shipping,
        refund_line_items: refund_line_items,
        transactions: transactions,
        note: note,
        notify: notify
      }
    }

    Rails.logger.info("Refund payload: #{payload}")

    response = @shopify_service.shopify_client.post(
      path: "/admin/api/2024-07/orders/#{@order.id}/refunds.json",
      body: payload,
      headers: { "Content-Type" => "application/json" }
    )

    if response.code == 200 then
      Rails.logger.info("Refund create: #{response.body}")
      render json: response.body
    else
      Rails.logger.error("Refund create error: #{response.body}")
      render json: response.body
    end
  end

  def calculate_refund
    Rails.logger.info("Got params: #{params}")
    permitted = params.permit(
      :currency, refund_line_items: [:line_item_id, :quantity, :restock_type])

    refund_line_items, currency = permitted.values_at(:refund_line_items, :currency)

    payload = {
      refund: {
        currency: currency,
        shipping: { full_refund: false, amount: 0 },
        refund_line_items: refund_line_items&.map do |item|
          {
            line_item_id: item[:line_item_id],
            quantity: item[:quantity],
            restock_type: item[:restock_type] || "no_restock"
          } || []
        end
      }
    }

    response = @shopify_service.shopify_client.post(
      path: "/admin/api/2024-07/orders/#{@order.id}/refunds/calculate.json",
      body: payload,
      headers: { "Content-Type" => "application/json" }
    )

    if response.code == 200 then
      Rails.logger.info("Refund calc: #{response.body}")
      render json: response.body
    else
      Rails.logger.error("Refund calc error: #{response.body}")
      render json: response.body
    end
  end

end
