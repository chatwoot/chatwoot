class DataImportErrorFinder
  RESULTS_LIMIT = 5

  def initialize(data_import)
    @data_import = data_import
  end

  def import_errors
    @data_import.import_errors.non_skip_logs.order(created_at: :desc).limit(RESULTS_LIMIT)
  end
end
