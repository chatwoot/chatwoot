class DataImports::Intercom::BaseJob < ApplicationJob
  queue_as :low

  retry_on DataImports::Intercom::Client::Error, wait: 1.minute, attempts: 3 do |job, error|
    job.fail_import!(error)
  end

  retry_on DataImports::Intercom::Client::RateLimitError, wait: 1.minute, attempts: 5 do |job, error|
    job.fail_import!(error)
  end

  def fail_import!(error)
    data_import = arguments.first
    run_id = arguments.length > 1 ? arguments.last : nil
    return if data_import.blank? || skip_import?(data_import, run_id)

    DataImports::Intercom::Importer.new(data_import: data_import, run_id: run_id).fail!(error)
  end

  private

  def skip_import?(data_import, run_id = nil)
    data_import.reload
    data_import.abandoned? || data_import.failed? || data_import.completed? ||
      data_import.completed_with_errors? || stale_import_run?(data_import, run_id)
  end

  def stale_import_run?(data_import, run_id)
    active_run_id = data_import.active_intercom_import_run_id
    active_run_id.present? && active_run_id != run_id
  end

  def importer_for(data_import, run_id = nil)
    DataImports::Intercom::Importer.new(data_import: data_import, run_id: run_id)
  end

  def fail_unexpected_error(importer, error)
    raise error if error.is_a?(DataImports::Intercom::Client::Error)

    importer&.fail!(error)
    raise error
  end
end
