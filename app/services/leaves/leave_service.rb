# frozen_string_literal: true

class Leaves::LeaveService
  pattr_initialize [:account!, :account_user!, :current_user!]

  def create(params)
    leave = account_user.leaves.build(filtered_params(params))
    leave.account = account
    
    if leave.save
      notify_leave_creation(leave)
      { success: true, leave: leave }
    else
      { success: false, errors: leave.errors.full_messages }
    end
  end

  def update(leave, params)
    if leave.update(filtered_params(params))
      notify_leave_update(leave)
      { success: true, leave: leave }
    else
      { success: false, errors: leave.errors.full_messages }
    end
  end

  def cancel(leave)
    return { success: false, errors: ['Cannot cancel approved leave'] } if leave.approved?
    
    if leave.update(status: 'cancelled')
      notify_leave_cancellation(leave)
      { success: true, leave: leave }
    else
      { success: false, errors: leave.errors.full_messages }
    end
  end

  def list(filters = {})
    scope = policy_scope

    # Apply filters
    scope = scope.where(status: filters[:status]) if filters[:status].present?
    scope = scope.where(leave_type: filters[:leave_type]) if filters[:leave_type].present?
    
    if filters[:start_date].present? && filters[:end_date].present?
      scope = scope.by_date_range(filters[:start_date], filters[:end_date])
    end

    if filters[:user_id].present? && current_user_admin?
      scope = scope.joins(:account_user).where(account_users: { user_id: filters[:user_id] })
    end

    scope.includes(:account_user, :user, :approved_by).order(start_date: :desc)
  end

  private

  def filtered_params(params)
    allowed_params = [:start_date, :end_date, :leave_type, :reason]
    allowed_params << :status if current_user_admin?
    
    params.slice(*allowed_params)
  end

  def policy_scope
    Pundit.policy_scope(user_context, Leave)
  end

  def user_context
    {
      user: current_user,
      account: account,
      account_user: account.account_users.find_by(user: current_user)
    }
  end

  def current_user_admin?
    @current_user_admin ||= account.account_users.find_by(user: current_user)&.administrator?
  end

  def notify_leave_creation(leave)
    Rails.configuration.dispatcher.dispatch(
      LEAVE_CREATED,
      Time.zone.now,
      leave: leave,
      account: account,
      user: leave.user
    )
  end

  def notify_leave_update(leave)
    Rails.configuration.dispatcher.dispatch(
      LEAVE_UPDATED,
      Time.zone.now,
      leave: leave,
      account: account,
      user: leave.user
    )
  end

  def notify_leave_cancellation(leave)
    Rails.configuration.dispatcher.dispatch(
      LEAVE_CANCELLED,
      Time.zone.now,
      leave: leave,
      account: account,
      user: leave.user
    )
  end
end