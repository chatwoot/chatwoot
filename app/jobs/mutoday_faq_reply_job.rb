class MutodayFaqReplyJob < ApplicationJob
  # :high matches SendReplyJob. This is a speed-to-first-response feature; the work is a
  # few Redis reads and at most one 8 s model call, so it does not starve the queue.
  queue_as :high

  # ApplicationJob already discards ActiveJob::DeserializationError — that is the case
  # where the Message row is gone by the time we run, and there is nothing to reply to.

  # Redis is the single point every guard funnels through: the per-conversation marker is
  # claimed with SET NX and the rate limiter reserves against it. If Redis is unreachable
  # we cannot tell whether we already replied, so we fail closed and stop. Retrying would
  # storm the dead set with the loop guards effectively switched off.
  discard_on Redis::BaseError

  # A message we could not build is our own body construction being wrong, not a transient
  # fault — a retry produces the same invalid row. The block is what makes this stop:
  # without one, exhausted attempts re-raise and Sidekiq would retry three more times.
  retry_on ActiveRecord::RecordInvalid, attempts: 1 do |job, error|
    Rails.logger.error("[mutoday_faq_reply] outcome=failed stage=create_message error=#{error.class} job_id=#{job.job_id}")
  end

  # Everything else carries no retry_on and bubbles to Sidekiq's :max_retries: 3
  # (config/sidekiq.yml), which is the right answer for a genuinely transient fault.

  def perform(hook, message)
    # T3: wiring only. ReplyService lands in T9; until then this proves the event reaches
    # us on the LINE inbox and nowhere else, and that nothing is sent to a customer.
    Rails.logger.info(
      "[mutoday_faq_reply] outcome=noop hook_id=#{hook.id} conversation_id=#{message.conversation_id} " \
      "inbox_id=#{message.inbox_id} message_type=#{message.message_type}"
    )
  end
end
