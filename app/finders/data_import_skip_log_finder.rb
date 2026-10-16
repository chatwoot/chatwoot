class DataImportSkipLogFinder
  RESULTS_LIMIT = 5
  SOURCE_OBJECT_TYPES = %w[contact conversation message].freeze

  attr_reader :selected_source_object_type

  def initialize(data_import, params = {})
    @data_import = data_import
    @selected_source_object_type = valid_source_object_type(params[:skip_logs_type])
  end

  def skip_logs
    filtered_scope.order(created_at: :desc).limit(RESULTS_LIMIT)
  end

  def counts_by_type
    base_scope.group(:source_object_type).count
  end

  private

  def base_scope
    @base_scope ||= @data_import.import_errors.skip_logs
  end

  def filtered_scope
    return base_scope if selected_source_object_type.blank?

    base_scope.where(source_object_type: selected_source_object_type)
  end

  def valid_source_object_type(source_object_type)
    source_object_type if SOURCE_OBJECT_TYPES.include?(source_object_type)
  end
end
