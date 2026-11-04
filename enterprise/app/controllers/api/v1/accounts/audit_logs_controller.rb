class Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :check_admin_authorization?
  before_action :fetch_audit

  RESULTS_PER_PAGE = 25
  # 9999-12-31T23:59:59Z, beyond this the database cannot represent the timestamp
  MAX_EPOCH = 253_402_300_799

  def show
    @audit_logs = @audit_logs.page(params[:page]).per(RESULTS_PER_PAGE)
    @current_page = @audit_logs.current_page
    @total_entries = @audit_logs.total_count
    @per_page = RESULTS_PER_PAGE
  end

  private

  def fetch_audit
    unless audit_logs_enabled?
      @audit_logs = Current.account.associated_audits.none
      Rails.logger.warn("Audit logs are disabled for account #{Current.account.id}")
      return
    end

    @audit_logs = filtered_audit_logs.order(created_at: sort_direction)
  end

  def filtered_audit_logs
    scope = Current.account.associated_audits
    scope = scope.with_auditable_types(auditable_types) if auditable_types.present?
    scope = scope.search_by_user(params[:q]) if params[:q].is_a?(String) && params[:q].present?
    apply_date_window(scope)
  end

  def auditable_types
    Array.wrap(params[:types]).grep(String)
  end

  def apply_date_window(scope)
    window_start = parsed_time(params[:since])
    window_end = parsed_time(params[:until])
    scope = scope.created_after(window_start) if window_start
    scope = scope.created_before(window_end) if window_end
    scope
  end

  def sort_direction
    params[:sort] == 'asc' ? :asc : :desc
  end

  def parsed_time(value)
    return if value.blank?

    epoch = Integer(value)
    return unless epoch.between?(0, MAX_EPOCH)

    Time.zone.at(epoch)
  rescue ArgumentError, TypeError
    nil
  end

  def audit_logs_enabled?
    Current.account.feature_enabled?(:audit_logs)
  end
end
