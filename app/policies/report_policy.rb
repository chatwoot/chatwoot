class ReportPolicy < ApplicationPolicy
  def view?
    @account_user.administrator?
  end
end

ReportPolicy.prepend_mod_with('ReportPolicy')
