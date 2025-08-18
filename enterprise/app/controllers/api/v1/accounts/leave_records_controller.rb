class Api::V1::Accounts::LeaveRecordsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_leave_record, only: [:show, :update, :destroy, :approve, :reject]
  before_action :check_authorization

  def index
    @leave_records = policy_scope(Current.account.leave_records)
  end

  def show; end

  def create
    @leave_record = Current.account.leave_records.create!(permitted_params.merge(user: current_user))
  end

  def update
    render json: { error: 'Cannot update non-pending leave record' }, status: :unprocessable_entity and return unless @leave_record.pending?

    @leave_record.update!(permitted_params)
  end

  def destroy
    render json: { error: 'Cannot delete this leave record' }, status: :unprocessable_entity and return unless @leave_record.can_be_cancelled?

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
    @leave_record = leave_records_scope.find(params[:id])
  end

  def leave_records_scope
    if Current.account_user.administrator?
      Current.account.leave_records
    else
      Current.account.leave_records.where(user: current_user)
    end
  end
end
