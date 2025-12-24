class Api::V1::Accounts::PriorityGroupsController <  Api::V1::Accounts::BaseController
  before_action :set_account
  before_action :check_authorization

  def index
    render json: @account.priority_groups.select(:id, :name)
  end

  private

  def set_account
    @account = current_account
  end
end
