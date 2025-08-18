class Api::V1::Accounts::LeaveRecordsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_leave_record, only: [:show, :update, :destroy, :approve, :reject]
  before_action :check_authorization, only: [:index, :create]
  before_action :check_record_authorization, only: [:show, :update, :destroy, :approve, :reject]

  def index
    @leave_records = policy_scope(Current.account.leave_records)
  end

  def show; end

  def create
    @leave_record = Current.account.leave_records.create!(permitted_params.merge(user: current_user))
  end

  def update
    @leave_record.update!(permitted_params)
  end

  def destroy
    @leave_record.destroy!
    head :ok
  end

  def approve
    @leave_record.approve!(current_user)
    render :show
  end

  def reject
    @leave_record.reject!(current_user)
    render :show
  end

  private

  def permitted_params
    params.require(:leave_record).permit(:start_date, :end_date, :leave_type, :reason)
  end

  def fetch_leave_record
    @leave_record = policy_scope(Current.account.leave_records).find(params[:id])
  end

  def check_record_authorization
    authorize(@leave_record)
  end
end
