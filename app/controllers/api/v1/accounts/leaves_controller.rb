# frozen_string_literal: true

class Api::V1::Accounts::LeavesController < Api::V1::Accounts::BaseController
  before_action :fetch_leave, only: [:show, :update, :destroy, :approve, :reject]
  before_action -> { check_authorization(Leave) }, only: [:index, :create]
  before_action :authorize_leave, only: [:show, :update, :destroy]
  before_action :authorize_approval, only: [:approve, :reject]

  def index
    @leaves = leave_service.list(filter_params)
    render json: { leaves: serialize_leaves(@leaves) }
  end

  def show
    render json: { leave: serialize_leave(@leave) }
  end

  def create
    account_user = find_or_authorize_account_user
    service = Leaves::LeaveService.new(
      account: Current.account,
      account_user: account_user,
      current_user: Current.user
    )

    result = service.create(leave_params)

    if result[:success]
      render json: { leave: serialize_leave(result[:leave]) }, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def update
    result = leave_service.update(@leave, leave_params)

    if result[:success]
      render json: { leave: serialize_leave(result[:leave]) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def destroy
    if @leave.destroy
      head :ok
    else
      render json: { errors: @leave.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def approve
    service = Leaves::LeaveApprovalService.new(leave: @leave, approver: Current.user)
    result = service.approve(params[:comments])

    if result[:success]
      render json: { leave: serialize_leave(result[:leave]) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def reject
    service = Leaves::LeaveApprovalService.new(leave: @leave, approver: Current.user)
    result = service.reject(params[:reason])

    if result[:success]
      render json: { leave: serialize_leave(result[:leave]) }
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  private

  def fetch_leave
    @leave = Current.account.leaves.find(params[:id])
  end

  def authorize_leave
    authorize @leave
  end

  def authorize_approval
    authorize @leave, :approve?
  end

  def find_or_authorize_account_user
    if params[:user_id].present? && Current.account_user.administrator?
      user = Current.account.users.find(params[:user_id])
      Current.account.account_users.find_by!(user: user)
    else
      Current.account.account_users.find_by!(user: Current.user)
    end
  end

  def leave_service
    @leave_service ||= if @leave
                         Leaves::LeaveService.new(
                           account: Current.account,
                           account_user: @leave.account_user,
                           current_user: Current.user
                         )
                       else
                         # For index action, we don't have a specific leave
                         Leaves::LeaveService.new(
                           account: Current.account,
                           account_user: nil,
                           current_user: Current.user
                         )
                       end
  end

  def leave_params
    params.require(:leave).permit(:start_date, :end_date, :leave_type, :reason)
  end

  def filter_params
    params.permit(:status, :leave_type, :start_date, :end_date, :user_id)
  end

  def serialize_leave(leave)
    {
      id: leave.id,
      start_date: leave.start_date,
      end_date: leave.end_date,
      leave_type: leave.leave_type,
      status: leave.status,
      reason: leave.reason,
      days_count: leave.days_count,
      approved_by: leave.approved_by&.name,
      approved_at: leave.approved_at,
      user: {
        id: leave.user.id,
        name: leave.user.name,
        email: leave.user.email,
        avatar_url: leave.user.avatar_url
      },
      created_at: leave.created_at,
      updated_at: leave.updated_at
    }
  end

  def serialize_leaves(leaves)
    leaves.map { |leave| serialize_leave(leave) }
  end
end
