class DataImports::Intercom::BaseJob < DataImports::BaseJob
  retry_on(*DataImports::Importer::CONNECTION_ERRORS, wait: :polynomially_longer, attempts: 3) do |job, error|
    raise error if job.arguments.empty?

    job.fail_import!(error)
  end

  retry_on DataImports::Intercom::Client::Error, wait: 1.minute, attempts: 3 do |job, error|
    job.fail_import!(error)
  end

  retry_on DataImports::Intercom::Client::RateLimitError, wait: 1.minute, attempts: 5 do |job, error|
    job.fail_import!(error)
  end
end
