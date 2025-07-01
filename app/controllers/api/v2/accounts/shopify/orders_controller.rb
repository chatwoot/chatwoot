class Api::V2::Accounts::Shopify::OrdersController < Api::V1::Accounts::BaseController
  before_action :setup_shopify_context, only: [:show, :cancel_order, :calculate_refund, :refund_order, :order_fulfillments]
  before_action :fetch_order, only: [:show, :cancel_order, :calculate_refund, :refund_order, :order_fulfillments]

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

  ORDER_REFUND_MUT = <<~GRAPHQL
    mutation RefundLineItem($input: RefundInput!) {
      refundCreate(input: $input) {
        refund {
          id
          totalRefundedSet {
            presentmentMoney {
              amount
              currencyCode
            }
          }
        }
        userErrors {
          field
          message
        }
      }
    }
  GRAPHQL

  ORDER_FULFILL_QUERY = <<~GRAPHQL
  query($id: ID!) {
      order(id: $id) {
        suggestedRefund {
          maximumRefundableSet {
            presentmentMoney {
          		amount
        		  currencyCode
            }
            shopMoney {
              amount
              currencyCode
            }
          }
          suggestedTransactions {
            gateway
            parentTransaction {
              id
            }
          }
        }
        fulfillments(first: 100) {
          fulfillmentLineItems(first: 100) {
            nodes {
              id
              quantity
              lineItem {
                id
              }
            }
          }
        }
        lineItems(first: 100) {
          nodes {
            id
            refundableQuantity
          }
        }
      }
    }
  GRAPHQL

#  ORDER_FULFILL_QUERY -> EXAMPLE RESPONSE
#  {
#   "data": {
#     "order": {
#     "transactions": [
#         {
#           "id": "gid://shopify/OrderTransaction/8117248688438",
#           "gateway": "bogus",
#           "kind": "SALE",
#           "status": "SUCCESS",
#           "amountSet": {
#             "shopMoney": {
#               "amount": "1274400.0",
#               "currencyCode": "INR"
#             }
#           }
#         },
#       "suggestedRefund": {
#         "maximumRefundableSet": {
#           "presentmentMoney": {
#             "amount": "1274400.0",
#             "currencyCode": "INR"
#           },
#           "shopMoney": {
#             "amount": "1274400.0",
#             "currencyCode": "INR"
#           }
#         }
#       },
#       "fulfillments": [
#         {
#           "fulfillmentLineItems": {
#             "nodes": [
#               {
#                 "id": "gid://shopify/FulfillmentLineItem/14505947889974",
#                 "quantity": 1,
#                 "lineItem": {
#                   "id": "gid://shopify/LineItem/16655992488246"
#                 }
#               }
#             ]
#           }
#         }
#       ],
#       "lineItems": {
#         "nodes": [
#           {
#             "id": "gid://shopify/LineItem/16655992455478",
#             "refundableQuantity": 6
#           },
#           {
#             "id": "gid://shopify/LineItem/16655992488246",
#             "refundableQuantity": 6
#           },
#           {
#             "id": "gid://shopify/LineItem/16655992521014",
#             "refundableQuantity": 1
#           }
#         ]
#       }
#     }
#   },
#   "extensions": {
#     "cost": {
#       "requestedQueryCost": 34,
#       "actualQueryCost": 9,
#       "throttleStatus": {
#         "maximumAvailable": 2000,
#         "currentlyAvailable": 1991,
#         "restoreRate": 100
#       }
#     }
#   }
# } 

  def show
    render json: {order: @order}
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
      # job = response.data.orderCancel.job # job => {id}
      errors = response.data.orderCancel.orderCancelUserErrors

      if errors.any?
        render json: {errors: errors.map(&:to_h)}, status: :unprocessable_entity
      else

        render json: {message: I18n.t('shopify.order_cancellation_process') }
      end
    end
  end

  def refund_order
    permitted = params.permit(:note, :notify, :currency, refund_line_items: [:line_item_id, :quantity, :restock_type], transactions: [:parent_id, :amount,:kind, :gateway, :order_id], shipping: [:amount, :tax, :maximum_refundable])

    refund_line_items, transactions, note, notify, currency, shipping = permitted.values_at(:refund_line_items, :transactions, :note, :notify, :currency, :shipping)

    payload = {
      # refund: {
        currency: currency,
        shipping: {
          amount: 0,
          fullRefund: false,
        },
        refundLineItems: (refund_line_items&.map do |item|
          item.merge(restockType: (item[:restock_type] || "no_restock").upcase,
                     lineItemId:  "gid://shopify/LineItem/#{item[:line_item_id]}",
                     locationId: item[:location_id]
          ).except(:line_item_id, :location_id, :restock_type)
        end || []),
        transactions: (transactions&.map do |item|
          item.merge(kind: "REFUND", parentId: item[:parent_id], orderId: "gid://shopify/Order/#{item[:order_id]}" ).except(:parent_id, :order_id)
        end || []),
        note: note,
        notify: notify,
        orderId: "gid://shopify/Order/#{@order.id}" 
      # }
    }

    Rails.logger.info("Refund payload: #{payload}")

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        ORDER_REFUND_MUT,
        input:   payload,
      )

      # Handle the response
      # job = response.data.orderCancel.job # job => {id}
      errors = response.data.refundCreate.userErrors

      if errors.any?
        render json: {errors: errors.map(&:to_h)}, status: :unprocessable_entity
      else
        Rails.logger.info("Order refund created #{response.data.refundCreate}")
        render json: {message: I18n.t('shopify.order_cancellation_process') }
      end
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

  def order_fulfillments
    orderGid =  "gid://shopify/Order/#{@order.id}"

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        ORDER_FULFILL_QUERY,
        id: orderGid,
      )

      render json: {order: deep_symbolize(response.data.order)}
    end
  end

  def deep_symbolize(obj)
    case obj
    when OpenStruct
      deep_symbolize(obj.to_h)
    when Hash
      obj.each_with_object({}) do |(k, v), result|
        result[k.to_sym] = deep_symbolize(v)
      end
    when Array
      obj.map { |v| deep_symbolize(v) }
    else
      obj
    end
  end
end
