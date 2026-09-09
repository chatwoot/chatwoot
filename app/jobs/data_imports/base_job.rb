class DataImports::BaseJob < ApplicationJob
  queue_as :low

  def fail_import!(error)
    data_import = arguments.first
    run_id = arguments.length > 1 ? arguments.last : nil
    return if data_import.blank? || skip_import?(data_import, run_id)

    importer_for(data_import, run_id).fail!(error)
  end

  private

  def skip_import?(data_import, run_id = nil)
    data_import.reload
    data_import.abandoned? || data_import.failed? || data_import.completed? ||
      data_import.completed_with_errors? || stale_import_run?(data_import, run_id)
  end

  def stale_import_run?(data_import, run_id)
    active_run_id = data_import.active_import_run_id
    active_run_id.present? && active_run_id != run_id
  end

  def importer_for(data_import, run_id = nil)
    source_class(data_import).importer_class.new(data_import: data_import, run_id: run_id)
  end

  def fail_unexpected_error(importer, error)
    raise error if source_class(arguments.first).client_error?(error)

    importer&.fail!(error)
    raise error
  end

  def contacts_page_job_class(data_import)
    source_class(data_import).contacts_page_job_class
  end

  def conversations_page_job_class(data_import)
    source_class(data_import).conversations_page_job_class
  end

  def source_class(data_import)
    DataImports::Source.source_class(data_import.source_provider)
  end
end
