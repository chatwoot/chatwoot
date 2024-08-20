class ReportPolicy < ApplicationPolicy
  def view?
    @account_user.administrator? || @account_user.custom_role&.permissions&.include?('report_manage')
  end
end
