class Api::V1::Accounts::Conversations::ShopeeController < Api::V1::Accounts::Conversations::BaseController
  def vouchers
    @vouchers = Shopee::Voucher.sendable
  end

  def orders
    @orders = Shopee::Order.limit(10)
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
