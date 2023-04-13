# module Enterprise::Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::BaseController
class Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_audit
  before_action :prepend_view_paths

  RESULTS_PER_PAGE = 15

  # Prepend the view path to the enterprise/app/views won't be available by default
  def prepend_view_paths
    prepend_view_path 'enterprise/app/views/'
  end

  def show
    @audit_logs = @audit_logs.page(params[:page]).per(RESULTS_PER_PAGE)
    @current_page = @audit_logs.current_page
    @total_entries = @audit_logs.total_count
    @per_page = RESULTS_PER_PAGE
  end

  private

  def fetch_audit
    @audit_logs = Current.account.associated_audits.order(created_at: :desc)
  end
end
