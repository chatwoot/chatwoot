class DataImports::Freshdesk::BaseJob < DataImports::BaseJob
  retry_on DataImports::Freshdesk::Client::Error, wait: 1.minute, attempts: 3 do |job, error|
    job.fail_import!(error)
  end

  retry_on DataImports::Freshdesk::Client::RateLimitError, wait: 1.minute, attempts: 5 do |job, error|
    job.fail_import!(error)
  end
end
