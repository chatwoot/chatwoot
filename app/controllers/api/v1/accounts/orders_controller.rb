class Api::V1::Accounts::OrdersController < Api::V1::Accounts::BaseController
  include Sift
  sort_on :created_at, internal_name: :order_on_created_at, type: :scope, scope_params: [:direction]
  sort_on :total, type: :decimal
  sort_on :contact_name, internal_name: :order_on_contact_name, type: :scope, scope_params: [:direction]

  RESULTS_PER_PAGE = 15

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :search]

  def index
    orders = Current.account.orders
    orders = apply_filters(orders)

    @orders = fetch_orders(orders)
    @orders_count = @orders.total_count
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    orders = Current.account.orders.search(params[:q].strip)
    @orders = fetch_orders(orders)
    @orders_count = @orders.total_count
    render :index
  end

  private

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_orders(orders)
    filtrate(orders)
      .includes(:contact, :created_by, :conversation, :order_items)
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

  def check_authorization
    authorize(Order)
  end

  def apply_filters(orders)
    orders = orders.by_status(params[:status]) if params[:status].present? && params[:status] != 'all'
    orders = orders.search(params[:search]) if params[:search].present?
    apply_date_filter(orders)
  end

  def apply_date_filter(orders)
    return orders if params[:date_range].blank? || params[:date_range] == 'all'

    case params[:date_range]
    when 'today' then orders.filter_by_created_at(Time.zone.today.all_day)
    when 'this_week' then orders.filter_by_created_at(Time.zone.today.all_week)
    when 'this_month' then orders.filter_by_created_at(Time.zone.today.all_month)
    when 'custom' then apply_custom_date_filter(orders)
    else orders
    end
  end

  def apply_custom_date_filter(orders)
    return orders if params[:date_from].blank? && params[:date_to].blank?

    orders.filter_by_created_at(custom_date_start..custom_date_end)
  end

  def custom_date_start
    return Time.zone.at(0) if params[:date_from].blank?

    Time.zone.parse(params[:date_from]).beginning_of_day
  end

  def custom_date_end
    return Time.zone.now.end_of_day if params[:date_to].blank?

    Time.zone.parse(params[:date_to]).end_of_day
  end
end
