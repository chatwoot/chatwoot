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
      @orders = @orders.where(status: ['PROCESSED', 'READY_TO_SHIP'])
    when 'shipping'
      @orders = @orders.where(status: ['SHIPPED', 'TO_CONFIRM_RECEIVE'])
    when 'delivered'
      @orders = @orders.where(status: 'COMPLETED')
    when 'cancelled'
      @orders = @orders.where(status: 'CANCELLED')
    when 'returned_refunded'
      @orders = @orders.where(status: 'TO_RETURN')
    end
  end

  def products
    if params[:keyword].blank?
      @products = Shopee::Item.none
    else
      @products = @conversation.inbox.channel.items.search_by_name(params[:keyword])
    end
  end

  def send_voucher
    render json: { success: true }
  end

  def send_order
    render json: { success: true }
  end

  def send_product
    render json: { success: true }
  end
end
