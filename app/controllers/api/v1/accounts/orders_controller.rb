class Api::V1::Accounts::OrdersController < Api::V1::Accounts::BaseController
  include Sift

  before_action :fetch_order, only: [:show]
  before_action :fetch_contact_orders, only: [:contact_order]
  before_action :set_current_page, only: [:index, :search, :filter]

  RESULTS_PER_PAGE = 15

  def index
    @orders_count = Current.account.orders.count
    @orders = fetch_orders(Current.account.orders)
  end

  # GET /orders/:id
  def all_orders
    @orders = Current.account.orders
  end

  def show; end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    orders = all_orders.joins(:contact).where(
      'order_number ILIKE :search OR created_via ILIKE :search OR platform ILIKE :search OR contacts.name ILIKE :search
        OR contacts.phone_number ILIKE :search',
      search: "%#{params[:q].strip}%"
    )
    @orders_count = orders.count
    @orders = fetch_orders(orders)
  end

  def filter
    result = ::Integrations::FilterService.new(Current.account, Current.user, params.permit!).perform
    orders = result[:orders]
    @orders_count = result[:count]
    @orders = fetch_orders(orders)
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render_could_not_create_error(e.message)
  end

  def contact_order; end

  private

  def fetch_contact_orders
    @orders = Current.account.orders.where(contact_id: params[:contact_id])
  end

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_orders(orders)
    filtrate(orders)
      .includes(:order_items)
      .page(@current_page).per(RESULTS_PER_PAGE)
  end

  def fetch_order
    @order = Current.account.orders.includes(:order_items).find(params[:id])
  end

  def order_params
    params.require(:order).permit(:order_number, :contact_id, :order_key, :created_via, :platform, :status, :date_created, :date_modified,
                                  :discount_total, :shipping_total, :total, :prices_include_tax, :payment_method, :transaction_id, :set_paid)
  end

  def resolved_orders
    return @resolverd_orders if @resolverd_orders

    @resolverd_orders = Current.account.orders.resolverd_orders
  end
end
