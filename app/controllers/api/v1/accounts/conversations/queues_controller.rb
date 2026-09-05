class Api::V1::Accounts::Conversations::QueuesController < Api::V1::Accounts::Conversations::BaseController
  before_action :check_queue_admin_authorization!

  def show
    entry = @conversation.conversation_queue
    return render json: { queue: nil } if entry.blank?

    render json: { queue: queue_payload(entry) }
  end

  def destroy
    entry = ChatQueue::QueueService.new(account: Current.account)
                                   .remove_from_queue(@conversation, reason: :resolved)

    return render json: { error: 'No waiting queue entry found' }, status: :unprocessable_entity if entry.blank?

    open_conversation_if_queued!
    Queue::ProcessQueueJob.perform_later(Current.account.id, @conversation.inbox_id)

    render json: { queue: queue_payload(entry.reload) }
  end

  private

  def check_queue_admin_authorization!
    return if Current.account_user&.administrator?
    return if current_user.is_a?(SuperAdmin)

    raise Pundit::NotAuthorizedError
  end

  def open_conversation_if_queued!
    return unless @conversation.queued?

    @conversation.update!(status: :open)
  end

  def queue_payload(entry)
    {
      id: entry.id,
      status: entry.status,
      position: entry.position,
      queued_at: entry.queued_at,
      assigned_at: entry.assigned_at,
      left_at: entry.left_at
    }
  end
end
