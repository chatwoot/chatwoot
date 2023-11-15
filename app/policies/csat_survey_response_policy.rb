class CsatSurveyResponsePolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def metrics?
    @account_user.administrator?
  end

  def download?
    @account_user.administrator?
  end
end
