class DataImports::Freshdesk::BaseJob < DataImports::BaseJob
  DEFAULT_RATE_LIMIT_WAIT = 1.minute

  retry_on DataImports::Freshdesk::Client::Error, wait: 1.minute, attempts: 3 do |job, error|
    job.fail_import!(error)
  end

  retry_on DataImports::Freshdesk::Client::RateLimitError, wait: DEFAULT_RATE_LIMIT_WAIT, attempts: 5 do |job, error|
    job.fail_import!(error)
  end

  discard_on CustomExceptions::DataImport::FreshdeskTicketLimitError

  def retry_job(options = {})
    error = options[:error]
    options = options.merge(wait: rate_limit_wait(error)) if error.is_a?(DataImports::Freshdesk::Client::RateLimitError)
    super(options)
  end

  private

  def rate_limit_wait(error)
    retry_after = error.retry_after.to_i
    retry_after.positive? ? retry_after.seconds : DEFAULT_RATE_LIMIT_WAIT
  end
end
