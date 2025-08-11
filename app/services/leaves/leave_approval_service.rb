# frozen_string_literal: true

class Leaves::LeaveApprovalService
  pattr_initialize [:leave!, :approver!]

  def approve(comments = nil)
    return error_response('Leave is not pending') unless leave.pending?
    return error_response('You are not authorized to approve this leave') unless can_approve?

    ActiveRecord::Base.transaction do
      leave.update!(
        status: 'approved',
        approved_by: approver,
        approved_at: Time.current
      )

      create_approval_note(comments) if comments.present?
      notify_approval
      reassign_conversations_if_needed
    end

    { success: true, leave: leave }
  rescue ActiveRecord::RecordInvalid => e
    error_response(e.record.errors.full_messages.join(', '))
  rescue StandardError => e
    Rails.logger.error "LeaveApprovalService error: #{e.message}"
    error_response('An error occurred while approving the leave')
  end

  def reject(reason)
    return error_response('Leave is not pending') unless leave.pending?
    return error_response('You are not authorized to reject this leave') unless can_approve?
    return error_response('Rejection reason is required') if reason.blank?

    ActiveRecord::Base.transaction do
      leave.update!(
        status: 'rejected',
        approved_by: approver,
        approved_at: Time.current
      )

      create_rejection_note(reason)
      notify_rejection
    end

    { success: true, leave: leave }
  rescue ActiveRecord::RecordInvalid => e
    error_response(e.record.errors.full_messages.join(', '))
  rescue StandardError => e
    Rails.logger.error "LeaveApprovalService error: #{e.message}"
    error_response('An error occurred while rejecting the leave')
  end

  private

  def can_approve?
    account_user = leave.account.account_users.find_by(user: approver)
    account_user&.administrator?
  end

  def error_response(message)
    { success: false, errors: [message] }
  end

  def create_approval_note(comments)
    # This would create a note/activity log if such system exists
    # For now, we'll just log it
    Rails.logger.info "Leave #{leave.id} approved by #{approver.name} with comments: #{comments}"
  end

  def create_rejection_note(reason)
    # This would create a note/activity log if such system exists
    # For now, we'll just log it
    Rails.logger.info "Leave #{leave.id} rejected by #{approver.name} with reason: #{reason}"
  end

  def notify_approval
    Rails.configuration.dispatcher.dispatch(
      LEAVE_APPROVED,
      Time.zone.now,
      leave: leave,
      approved_by: approver,
      account: leave.account,
      user: leave.user
    )
  end

  def notify_rejection
    Rails.configuration.dispatcher.dispatch(
      LEAVE_REJECTED,
      Time.zone.now,
      leave: leave,
      rejected_by: approver,
      account: leave.account,
      user: leave.user
    )
  end

  def reassign_conversations_if_needed
    # If the leave starts today or is already active, reassign conversations
    return unless leave.start_date <= Date.current

    account_user = leave.account.account_users.find_by(user_id: leave.user_id)
    ReassignConversationsJob.perform_later(account_user)
  end
end
