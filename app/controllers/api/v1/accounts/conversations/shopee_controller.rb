class Api::V1::Accounts::Conversations::ShopeeController < Api::V1::Accounts::Conversations::BaseController
  def vouchers
    @vouchers = @conversation.inbox.channel.vouchers.sendable
  end

  def orders
    @orders = @conversation.inbox.channel.orders
                           .where(buyer_user_id: @conversation.contact.identifier)
    case params[:order_status].to_s.downcase
    when 'unpaid'
      @orders = @orders.where(status: ['UNPAID'])
    when 'picking'
      @orders = @orders.where(status: %w[PROCESSED READY_TO_SHIP])
    when 'shipping'
      @orders = @orders.where(status: %w[SHIPPED TO_CONFIRM_RECEIVE])
    when 'delivered'
      @orders = @orders.where(status: 'COMPLETED')
    when 'cancelled'
      @orders = @orders.where(status: 'CANCELLED')
    when 'returned_refunded'
      @orders = @orders.where(status: 'TO_RETURN')
    end
  end

  def products
    @products = if params[:keyword].blank?
                  Shopee::Item.none
                else
                  @conversation.inbox.channel.items.search_by_name(params[:keyword])
                end
  end

  def send_voucher
    user = Current.user || current_account
    @message = Messages::MessageBuilder.new(user, @conversation, voucher_params).perform
    render action: 'send_message'
  end

  def send_order
    user = Current.user || current_account
    @message = Messages::MessageBuilder.new(user, @conversation, order_params).perform
    render action: 'send_message'
  end

  def send_product
    user = Current.user || current_account
    @message = Messages::MessageBuilder.new(user, @conversation, product_params).perform
    render action: 'send_message'
  end

  private

  def voucher_params
    {
      content: nil,
      private: false,
      message_type: 'outgoing',
      content_type: 'shopee_card',
      attachments: [],
      content_attributes: {
        original: {
          shop_id: @conversation.inbox.channel.shop_id,
          voucher_id: params[:voucher_id],
          voucher_code: params[:voucher_code]
        }
      }
    }
  end

  def order_params
    {
      content: nil,
      private: false,
      message_type: 'outgoing',
      content_type: 'shopee_card',
      attachments: [],
      content_attributes: {
        original: {
          shop_id: @conversation.inbox.channel.shop_id,
          order_sn: params[:order_number]
        }
      }
    }
  end

  def product_params
    {
      content: nil,
      private: false,
      message_type: 'outgoing',
      content_type: 'shopee_card',
      attachments: [],
      content_attributes: {
        original: {
          shop_id: @conversation.inbox.channel.shop_id,
          item_ids: params[:product_codes]
        }
      }
    }
  end
end
