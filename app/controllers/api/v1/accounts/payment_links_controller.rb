class Api::V1::Accounts::PaymentLinksController < Api::V1::Accounts::BaseController
  include Sift
  sort_on :created_at, internal_name: :order_on_created_at, type: :scope, scope_params: [:direction]
  sort_on :amount, type: :decimal
  sort_on :contact_name, internal_name: :order_on_contact_name, type: :scope, scope_params: [:direction]

  RESULTS_PER_PAGE = 15

  before_action :check_authorization
  before_action :set_current_page, only: [:index, :search, :filter]

  def index
    payment_links = Current.account.payment_links
    payment_links = apply_filters(payment_links)

    @payment_links = fetch_payment_links(payment_links)
    @payment_links_count = @payment_links.total_count
  end

  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    payment_links = Current.account.payment_links.search(params[:q].strip)
    @payment_links = fetch_payment_links(payment_links)
    @payment_links_count = @payment_links.total_count
    render :index
  end

  def filter
    result = ::PaymentLinks::FilterService.new(Current.account, Current.user, params.permit!).perform
    payment_links = result[:payment_links]
    @payment_links_count = result[:count]
    @payment_links = fetch_payment_links(payment_links)
    render :index
  rescue CustomExceptions::CustomFilter::InvalidAttribute,
         CustomExceptions::CustomFilter::InvalidOperator,
         CustomExceptions::CustomFilter::InvalidQueryOperator,
         CustomExceptions::CustomFilter::InvalidValue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def export
    Account::PaymentLinksExportJob.perform_later(Current.account.id, Current.user.id)
    head :ok
  end

  private

  def set_current_page
    @current_page = params[:page] || 1
  end

  def fetch_payment_links(payment_links)
    filtrate(payment_links)
      .includes(:contact, :created_by, :conversation)
      .page(@current_page)
      .per(RESULTS_PER_PAGE)
  end

  def check_authorization
    authorize(PaymentLink)
  end

  def apply_filters(payment_links)
    payment_links = payment_links.by_status(params[:status]) if params[:status].present? && params[:status] != 'all'
    payment_links = payment_links.search(params[:search]) if params[:search].present?
    if params[:amount_min].present? || params[:amount_max].present?
      payment_links = payment_links.filter_by_amount_range(params[:amount_min], params[:amount_max])
    end
    apply_date_filter(payment_links)
  end

  def apply_date_filter(payment_links)
    return payment_links if params[:date_range].blank? || params[:date_range] == 'all'

    case params[:date_range]
    when 'today'
      payment_links.filter_by_created_at(Time.zone.today.all_day)
    when 'this_week'
      payment_links.filter_by_created_at(Time.zone.today.all_week)
    when 'this_month'
      payment_links.filter_by_created_at(Time.zone.today.all_month)
    when 'custom'
      if params[:date_from].present? || params[:date_to].present?
        start_date = params[:date_from].present? ? Time.zone.parse(params[:date_from]).beginning_of_day : Time.zone.at(0)
        end_date = params[:date_to].present? ? Time.zone.parse(params[:date_to]).end_of_day : Time.zone.now.end_of_day
        payment_links.filter_by_created_at(start_date..end_date)
      else
        payment_links
      end
    else
      payment_links
    end
  end
end
