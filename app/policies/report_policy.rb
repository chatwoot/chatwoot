class ReportPolicy < ApplicationPolicy
  def view?
    @account_user.administrator?
  end
end

ReportPolicy.prepend(Enterprise::ReportPolicy)
