class BulkProcessingRequestPolicy < ApplicationPolicy
  def index?
    @account_user.administrator?
  end

  def show?
    @account_user.administrator?
  end

  def download_errors?
    @account_user.administrator?
  end

  def cancel?
    @account_user.administrator?
  end

  def dismiss?
    @account_user.administrator?
  end
end
