class CsatSurveyResponsePolicy < ApplicationPolicy
  def index?
    report_access?
  end

  def metrics?
    report_access?
  end

  def download?
    return false if restricted_agent?

    report_access?
  end

  private

  def report_access?
    return true if @account_user.administrator?

    @account_user.agent? && @account_user.custom_role_id.blank?
  end

  def restricted_agent?
    @account_user.agent? && @account_user.custom_role_id.blank?
  end
end

CsatSurveyResponsePolicy.prepend_mod_with('CsatSurveyResponsePolicy')
