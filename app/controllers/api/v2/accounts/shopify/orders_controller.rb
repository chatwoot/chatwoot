class Api::V2::Accounts::Shopify::OrdersController < Api::V1::Accounts::BaseController
  before_action :setup_shopify_context, only: [:show, :cancel_order]
  before_action :fetch_order, only: [:show, :cancel_order]

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
    Rails.logger.info("PARAMS: #{params.inspect}")

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
    Rails.logger.info("Order GID: #{orderGid}")

    # input = {
    #   orderId:   orderGid,
    #   reason:   permitted[:reason],
    #   refund:  permitted[:refund],
    #   restock:   permitted[:restock],
    #   notifyCustomer:  permitted[:notify_customer],
    #   staffNote: "Cancelled via api"
    # }

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

      Rails.logger.info("Got here at last #{response.data}")
      # Handle the response
      job = response.data.orderCancel.job # job => {id}
      errors = response.data.orderCancel.orderCancelUserErrors

      if errors.any?
        Rails.logger.info("JSON errors: #{errors.map(&:to_h).to_json}")
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
end
