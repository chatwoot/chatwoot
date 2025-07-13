class Api::V2::Accounts::Shopify::OrdersController < Api::V1::Accounts::BaseController
  before_action :setup_shopify_context, only: [:show, :cancel_order, :calculate_refund, :refund_order, :fulfillment_create, :order_details, :return_calculate, :return_create, :fulfillment_orders]
  before_action :fetch_order, only: [:show, :cancel_order, :calculate_refund, :refund_order, :fulfillment_create, :order_details, :return_calculate, :return_create, :fulfillment_orders]

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

  ORDER_DETAILS_QUERY = <<~GRAPHQL
  query($id: ID!) {
      order(id: $id) {
        returns(first: 20) {
          nodes {
            status
            reverseFulfillmentOrders(first: 20) {
              nodes {
                lineItems(first:10) {
                  nodes {
                    fulfillmentLineItem {
                      id
                      quantity
                      lineItem {
                        id
                      }
                    }
                  }
                }
                
              }
            }
          }
        }
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
        fulfillments(first: 20) {
          name
          fulfillmentLineItems(first: 20) {
            nodes {
              id
              quantity
              lineItem {
                id
              }
            }
          }
        }
        lineItems(first: 10) {
          nodes {
            id
            refundableQuantity
            unfulfilledQuantity
          }
        }
      }
    }
  GRAPHQL

  RETURN_CREATE_QUERY=<<~GRAPHQL
    mutation ReturnCreate($returnInput: ReturnInput!) {
      returnCreate(returnInput: $returnInput) {
        userErrors {
          field
          message
        }
        return {
          id
          order {
            id
          }
        }
      }
    }
  GRAPHQL

  RETURN_CALCULATE_QUERY=<<~GRAPHQL
    query($orderId: ID!, $returnLineItems: [CalculateReturnLineItemInput!], $returnShippingFee: ReturnShippingFeeInput) {
      returnCalculate(input: {
        orderId:$orderId, 
        returnLineItems:$returnLineItems,
        returnShippingFee: $returnShippingFee
      }) {
        id
        returnLineItems {
          id
          fulfillmentLineItem {
            id
          }
          quantity
          subtotalSet {
            shopMoney {
              amount
              currencyCode
            }
          }
          restockingFee {
            amountSet {
            shopMoney {
              amount
              currencyCode
            }
            }
          }
          totalTaxSet {
            shopMoney {
              amount
              currencyCode
            }
          }
        }
        returnShippingFee {
          amountSet{
            shopMoney {
              amount
              currencyCode
            }
          }
        }
      }
    }
  GRAPHQL


ORDER_FULFILLMENT_ORDERS = <<~GRAPHQL
  query($orderId: ID!) {
    order(id: $orderId) {
      name
      shippingAddress {
        country
        firstName
        lastName
        city
        zip
        phone
        longitude
        latitude  
      }
      fulfillmentOrders(first:10) {
        nodes {
          id
          assignedLocation {
            address1
            address1
            zip
            countryCode
            province
            city
          }
          lineItems(first:10) {
            nodes {
              id
              remainingQuantity
              lineItem {
                id
              }
            }
          }
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

  FULFILLMENT_CREATE_MUTATION = <<~GRAPHQL
    mutation fulfillmentCreate($fulfillment: FulfillmentInput!) {
      fulfillmentCreate(fulfillment: $fulfillment, message: "Created via onehash chat") {
        fulfillment {
          id
        }
        userErrors {
          field
          message
        }
      }
    }
GRAPHQL

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
    permitted = params.permit(:note, :notify, :currency, refund_line_items: [:line_item_id, :quantity, :restock_type, :location_id], transactions: [:parent_id, :amount,:kind, :gateway, :order_id], shipping: [:amount, :tax, :maximum_refundable])

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
                     locationId: item[:restock_type] === "RETURN" ? "gid://shopify/Location/#{item[:location_id]}" : nil
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
        render json: deep_symbolize(response.data.refundCreate)
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

  def order_details
    orderGid =  "gid://shopify/Order/#{@order.id}"

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        ORDER_DETAILS_QUERY,
        id: orderGid,
      )
      
      Rails.logger.info "Before serialization: #{response.data.order.fulfillments[0].fulfillmentLineItems.nodes[0].quantity}"


      result =  {order: deep_symbolize(response.data.order)}
      
      Rails.logger.info "After serialization: #{result[:order][:fulfillments][0][:fulfillmentLineItems][:nodes][0][:quantity]}"

      render json: result
    end
  end

  def fulfillment_orders
    orderGid =  "gid://shopify/Order/#{@order.id}"

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        ORDER_FULFILLMENT_ORDERS,
        orderId: orderGid,
      )

      render json: {order: deep_symbolize(response.data.order)}
    end
  end


  def return_calculate
    permitted = params.permit(returnLineItems: [:fulfillmentLineItemId, :quantity, :restockingFeePercentage], returnShippingFee: [
      :amount, :currencyCode
    ])

    return_line_items, return_shipping_fee = permitted.values_at(:returnLineItems, :returnShippingFee)

    orderGid =  "gid://shopify/Order/#{@order.id}"

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        RETURN_CALCULATE_QUERY,
        orderId: orderGid,
        returnLineItems: return_line_items&.map do |item|
          item.merge(restockingFee: {
              percentage: item[:restockingFeePercentage]
          }).except(:restockingFeePercentage)
        end,
        returnShippingFee: {
          amount: return_shipping_fee
        }
      )

      render json: {refundable: deep_symbolize(response.data.returnCalculate)}
    end
  end

  def return_create
    permitted = params.permit(returnLineItems: [:fulfillmentLineItemId, :quantity, :restockingFeePercentage, :returnReason, :returnReasonNote], returnShippingFee: [
      :amount, :currencyCode
    ])

    return_line_items, return_shipping_fee = permitted.values_at(:returnLineItems, :returnShippingFee)

    orderGid =  "gid://shopify/Order/#{@order.id}"

    payload = {
        orderId: orderGid,
        returnLineItems: return_line_items&.map do |item|
          item.merge(restockingFee: {
              percentage: item[:restockingFeePercentage]
          }).except(:restockingFeePercentage)
        end,
        returnShippingFee: {
          amount: return_shipping_fee
        }
    }

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        RETURN_CREATE_QUERY,
        returnInput: payload
      )

      Rails.logger.info("Return create response: #{response.data}")
      if response.data.userErrors&.present?
        render json: {errors: errors.map(&:to_h)}, status: :unprocessable_entity
      else
        render json: {refundable: deep_symbolize(response.data.returnCalculate)}
      end
    end

  end


  def fulfillment_create
    permitted = params.permit(:notifyCustomer, originAddress: [ :address1, :address1, :zip, :countryCode, :city], lineItemsByFulfillmentOrder: [:fulfillmentOrderId, fulfillmentOrderLineItems: [:id, :quantity]], trackingInfo: [:company, :number, :numbers, :url, :urls])

    notifyCustomer, originAddress, lineItemsByFulfillmentOrder,trackingInfo = permitted.values_at(:notifyCustomer, :originAddress, :lineItemsByFulfillmentOrder, :trackingInfo)

    payload = {
      notifyCustomer: notifyCustomer,
      originAddress: originAddress,
      lineItemsByFulfillmentOrder: lineItemsByFulfillmentOrder,
      trackingInfo: trackingInfo
    }

    @shopify_service.shop.with_shopify_session do
      # Execute the mutation using the shopify_graphql gem
      response = ShopifyGraphql.execute(
        FULFILLMENT_CREATE_MUTATION,
        fulfillment: payload
      )

      Rails.logger.info("Fulfillment create response: #{response.data}")

      if response.data.userErrors&.present?
        render json: {errors: errors.map(&:to_h)}, status: :unprocessable_entity
      else
        render json: {refundable: deep_symbolize(response.data.fulfillment)}
      end
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
