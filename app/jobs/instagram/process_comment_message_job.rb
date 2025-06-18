class Instagram::ProcessCommentMessageJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 1.second, attempts: 8

  def perform(message, owner_instagram_id)
    @message = message
    key = format(::Redis::Alfred::IG_COMMENT_MESSAGE_MUTEX, sender_id: sender_id, post_id: post_id)
    with_lock(key) do
      Instagram::CommentMessageService.new(@message, owner_instagram_id).perform
    end
  end

  private

  def sender_id
    @message.dig(:from, :id)
  end

  def post_id
    @message.dig(:media, :id)
  end
end
