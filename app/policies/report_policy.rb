class ReportPolicy < ApplicationPolicy
  def view?
    # CommMate: Allow administrators or users with report_manage permission
    @account_user.administrator? || has_report_permission?
  end

  private

  def has_report_permission?
    @account_user.permissions.include?('report_manage')
  end
end

ReportPolicy.prepend_mod_with('ReportPolicy')
