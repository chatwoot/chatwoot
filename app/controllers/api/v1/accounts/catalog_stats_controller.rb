class Api::V1::Accounts::CatalogStatsController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def show
    render json: {
      products: product_stats,
      orders: order_stats,
      payment_links: payment_link_stats,
      currency: Current.account.catalog_settings&.currency || 'SAR'
    }
  end

  private

  def check_authorization
    authorize Product, :index?
  end

  def product_stats
    products = Current.account.products
    {
      total: products.count,
      in_stock: products.where('stock > 0 OR stock IS NULL').count,
      out_of_stock: products.where(stock: 0).count
    }
  end

  def order_stats
    orders = Current.account.orders
    {
      total: orders.count,
      paid: orders.paid.count,
      pending: orders.pending.count,
      initiated: orders.initiated.count,
      failed: orders.failed.count,
      cancelled: orders.cancelled.count,
      total_revenue: orders.paid.sum(:total).to_f
    }
  end

  def payment_link_stats
    payment_links = Current.account.payment_links
    {
      total: payment_links.count,
      paid: payment_links.paid.count,
      pending: payment_links.pending.count,
      initiated: payment_links.initiated.count,
      total_revenue: payment_links.paid.sum(:amount).to_f
    }
  end
end
