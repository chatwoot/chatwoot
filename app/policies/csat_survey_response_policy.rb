class CsatSurveyResponsePolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end
end
