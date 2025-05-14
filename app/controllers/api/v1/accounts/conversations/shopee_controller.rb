class Api::V1::Accounts::Conversations::ShopeeController < Api::V1::Accounts::Conversations::BaseController
  def vouchers
    @vouchers = Shopee::Voucher.sendable
  end

  def orders
    @orders = Shopee::Order.where(buyer_user_id: @conversation.contact.identifier)
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
    @products = Shopee::Item.all.sort_by { |item| 0 - item.meta['available_stock'].to_i }.first(30)
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
