# Records the Sidekiq fetch boundary for Captain response jobs without logging every job.
class CaptainResponseDequeuedLogger
  JOB_CLASS = 'Captain::Conversation::ResponseBuilderJob'.freeze

  def call(_worker, job, queue)
    log_dequeued(job, queue) if captain_v2_response_job?(job)
    yield
  end

  private

  def log_dequeued(job, queue)
    active_job_id = job.dig('args', 0, 'job_id')
    responding_to_message_id = job.dig('args', 0, 'arguments', 2)
    Sidekiq.logger.info(
      "[CAPTAIN][ResponseLifecycle] event=job_dequeued active_job_id=#{active_job_id} provider_job_id=#{job['jid']} " \
      "responding_to_message_id=#{responding_to_message_id} queue=#{queue}"
    )
  end

  def captain_v2_response_job?(job)
    return false unless job['wrapped'] == JOB_CLASS

    !job.dig('args', 0, 'arguments', 2).nil?
  end
end
