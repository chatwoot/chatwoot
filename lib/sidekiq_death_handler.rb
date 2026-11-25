# Reports jobs that exhausted their retries and landed in the dead set.
#
# Until this existed nothing watched that set, so a send that failed every attempt was
# discovered by the customer complaining rather than by monitoring — the dead set held
# hundreds of SendReplyJob failures nobody had been told about. The handler runs for
# every job class; SendReplyJob additionally resolves the message so the report names the
# account, inbox and conversation instead of an opaque id, and marks it failed, because a
# reply whose job died is one the agent is still reading as sent.
class SidekiqDeathHandler
  def self.call(job, exception)
    new(job, exception).report
  end

  def initialize(job, exception)
    @job = job
    @exception = exception
  end

  # The log line is the one thing here that is not best-effort; everything after it is, and
  # each step is wrapped on its own so no step can cost the next one. Resolving the message
  # hits the database, and the failures that fill the dead set are exactly the ones that
  # come with a database in trouble: an exception raised while building the context used to
  # take out the line reporting the original error AND the exception tracker call, so
  # monitoring recorded "handler failed" and lost the terminal failure it exists to
  # surface. The tracker sits between the report and the marking for the same reason it
  # does in SendReplyJob.report_exhausted_email_failure: a Sentry hiccup must not cost the
  # agent the only signal they can act on.
  def report
    suffix = safely('context') { context_suffix } || ''
    Rails.logger.error(
      "[SIDEKIQ][DEAD] #{job_class} jid=#{@job['jid']} queue=#{@job['queue']} " \
      "error=#{@exception.class}: #{@exception.message}#{suffix}"
    )
    safely('tracker') do
      ChatwootExceptionTracker.new(@exception, account: safely('account') { account }).capture_exception
    end
    safely('message status') { fail_message }
  rescue StandardError => e
    # A death handler that raises takes the reporting down with the job it was reporting.
    Rails.logger.error "[SIDEKIQ][DEAD] handler failed: #{e.message}"
  end

  private

  def safely(what)
    yield
  rescue StandardError => e
    Rails.logger.warn "[SIDEKIQ][DEAD] could not resolve #{what}: #{e.class}: #{e.message}"
    nil
  end

  # ActiveJob wraps the real class name; plain Sidekiq workers use 'class'.
  def job_class
    @job['wrapped'] || @job['class']
  end

  # NEVER logged, only used to resolve the message below. Arguments are job payloads:
  # WebhookJob carries the customer's message body and `secret: webhook.secret`
  # positionally, so dumping them here would put message content and a signing credential
  # into the log aggregator on any unexpected terminal failure. Key-based filtering does
  # not help with a bare secret in a positional array. The jid in the log line is enough to
  # pull the full payload from the dead set, where access is already controlled, and
  # ChatwootExceptionTracker ships it to Sentry with the same protection.
  def job_args
    payload = @job['args']&.first
    payload.is_a?(Hash) ? payload['arguments'] : @job['args']
  end

  def message
    return @message if defined?(@message)

    @message = job_class.to_s == 'SendReplyJob' ? Message.find_by(id: job_args&.first) : nil
  end

  def account
    message&.account
  end

  # The last place that can tell the agent. Every retry_on block in SendReplyJob marks the
  # message before giving up, but they only cover the exceptions they name: anything else
  # exhausts Sidekiq's own retries and lands here with the row still on `sent`, which the
  # dashboard draws as a delivered reply with a clock next to it.
  #
  # Through SendReplyJob.fail_message for the terminal-status and source_id rules it
  # already owns, and inside `safely` because it re-raises when it cannot write. That is
  # right inside a retry_on block, where the raise is what buries the job and brings it
  # here; here there is nothing left to escalate to, and a raise would cost the report.
  def fail_message
    return if message.blank?

    SendReplyJob.fail_message(message.id, failure_reason)
  end

  # Persisted for the agent to read, from a worker that never sets a locale, so the
  # account's has to be named here or every agent reads English. No InvalidLocale guard
  # like MessageTemplates::Template::CsatSurvey's: `locale` is an enum over
  # LANGUAGES_CONFIG, and all 42 of its values are in I18n.available_locales, so an
  # unloaded one is not reachable. A null column yields nil, which with_locale treats as
  # "leave it alone" and resolves to the default.
  def failure_reason
    I18n.with_locale(account&.locale) { I18n.t('errors.inboxes.channel.outgoing.send_failed_after_retries') }
  end

  def context_suffix
    return '' if message.blank?

    " account_id=#{message.account_id} inbox_id=#{message.inbox_id} " \
      "conversation_id=#{message.conversation_id} message_id=#{message.id}"
  end
end
