# module Enterprise::Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::BaseController
class Api::V1::Accounts::AuditLogsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_audit

  def show
    render json: @audit_logs
  end

  private

  def fetch_audit
    @audit_logs = Current.account.associated_audits
  end
end
