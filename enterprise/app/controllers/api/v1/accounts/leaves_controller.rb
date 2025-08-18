class Api::V1::Accounts::LeavesController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_leave, only: [:show, :update, :destroy, :approve, :reject]
  before_action :check_authorization

  def index
    @leaves = policy_scope(Current.account.leaves)
  end

  def show; end

  def create
    @leave = Current.account.leaves.create!(permitted_params.merge(user: current_user))
  end

  def update
    @leave.update!(permitted_params)
  end

  def destroy
    @leave.destroy!
    head :ok
  end

  def approve
    @leave.approve!(current_user)
    render :show
  end

  def reject
    @leave.reject!(current_user)
    render :show
  end

  private

  def permitted_params
    params.require(:leave).permit(:start_date, :end_date, :leave_type, :reason)
  end

  def fetch_leave
    @leave = Current.account.leaves.find_by(id: params[:id])
  end
end
