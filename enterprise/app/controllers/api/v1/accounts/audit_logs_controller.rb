class Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :check_admin_authorization?
  before_action :fetch_audit

  RESULTS_PER_PAGE = 15

  def show
    @audit_logs = @audit_logs.page(params[:page]).per(RESULTS_PER_PAGE)
    @current_page = @audit_logs.current_page
    @total_entries = @audit_logs.total_count
    @per_page = RESULTS_PER_PAGE
  end

  def latest_sign_ins
    unless audit_logs_enabled?
      render json: { error: 'Audit logs are disabled' }, status: :forbidden
      return
    end

    # Get the latest sign_in audit per associated_id
    audits = Enterprise::AuditLog.where(action: 'sign_in')
                                 .select('associated_id, MAX(created_at) as latest_sign_in_at')
                                 .group(:associated_id)

    render json: audits.map { |a| { associated_id: a.associated_id, latest_sign_in_at: a.latest_sign_in_at } }
  end

  private

  def fetch_audit
    @audit_logs = if audit_logs_enabled?
                    Current.account.associated_audits.order(created_at: :desc)
                  else
                    Current.account.associated_audits.none
                  end
    return if audit_logs_enabled?

    Rails.logger.warn("Audit logs are disabled for account #{Current.account.id}")
  end

  def audit_logs_enabled?
    Current.account.feature_enabled?(:audit_logs)
  end
end
