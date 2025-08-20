class Api::V1::Accounts::LeaveRecordsController < Api::V1::Accounts::EnterpriseAccountsController
  before_action :fetch_leave_record, only: [:show, :update, :destroy, :approve, :reject]
  before_action :check_authorization
  before_action :ensure_pending_status, only: [:update]
  before_action :ensure_can_be_cancelled, only: [:destroy]

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

  def ensure_pending_status
    return if @leave_record.pending?

    render_could_not_create_error(I18n.t('errors.leave_records.cannot_update_non_pending'))
  end

  def ensure_can_be_cancelled
    return if @leave_record.can_be_cancelled?

    render_could_not_create_error(I18n.t('errors.leave_records.cannot_delete'))
  end
end
