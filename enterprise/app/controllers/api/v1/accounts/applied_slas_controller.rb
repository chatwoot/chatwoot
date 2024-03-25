class Api::V1::Accounts::AppliedSlasController < Api::V1::Accounts::EnterpriseAccountsController
  include Sift
  include DateRangeHelper

  RESULTS_PER_PAGE = 25

  before_action :set_applied_slas, only: [:index, :metrics, :download]
  before_action :set_current_page, only: [:index]
  before_action :paginate_slas, only: [:index]
  before_action :check_admin_authorization?

  sort_on :created_at, type: :datetime

  def index; end

  def metrics
    @total_applied_slas = total_applied_slas
    @number_of_sla_breaches = number_of_sla_breaches
    @hit_rate = hit_rate
  end

  def download
    @breached_slas = breached_slas

    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = 'attachment; filename=breached_conversation.csv'
    render layout: false, formats: [:csv]
  end

  private

  def breached_slas
    @applied_slas.includes(:sla_policy).joins(:conversation)
                 .where.not(conversations: { status: :resolved })
                 .where(applied_slas: { sla_status: :missed })
  end

  def total_applied_slas
    @total_applied_slas ||= @applied_slas.count
  end

  def number_of_sla_breaches
    @number_of_sla_breaches ||= @applied_slas.missed.count
  end

  def hit_rate
    number_of_sla_breaches.zero? ? '100%' : "#{hit_rate_percentage}%"
  end

  def hit_rate_percentage
    ((total_applied_slas - number_of_sla_breaches) / total_applied_slas.to_f * 100).round(2)
  end

  def set_applied_slas
    initial_query = Current.account.applied_slas.includes(:conversation)
    @applied_slas = initial_query
                    .filter_by_date_range(range)
                    .filter_by_inbox_id(params[:inbox_id])
                    .filter_by_team_id(params[:team_id])
                    .filter_by_sla_policy_id(params[:sla_policy_id])
                    .filter_by_label_list(params[:label_list])
                    .filter_by_assigned_agent_id(params[:assigned_agent_id])
  end

  def paginate_slas
    @applied_slas = @applied_slas.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def set_current_page
    @current_page = params[:page] || 1
  end
end
