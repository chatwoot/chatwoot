# module Enterprise::Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::BaseController
class Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_audit

  def show
    @audit_logs = @audit_logs.page(params[:page]).per(params[:per_page])
    render json: {
      audit_logs: @audit_logs,
      current_page: @audit_logs.current_page,
      per_page: @audit_logs.limit_value,
      total_entries: @audit_logs.total_count
    }
  end

  private

  def fetch_audit
    @audit_logs = Current.account.associated_audits
  end
end
