class DataImports::CreationService
  def initialize(account:, initiated_by:, source_params:)
    @account = account
    @initiated_by = initiated_by
    @source_params = source_params.symbolize_keys
    @access_token = @source_params[:access_token].to_s.strip
    @provider = @source_params[:source_provider].to_s
    @source_class = DataImports::Source.source_class(@provider)
  end

  def perform
    return if active_import?

    totals = validate_source
    @account.with_lock do
      next if active_import?

      @account.data_imports.new(attributes(totals)).tap do |data_import|
        data_import.assign_active_import_run_id
        data_import.save!
      end
    end
  end

  private

  def validate_source
    @source_class.credentials_validator(source_params: @source_params, import_types: import_types).perform
  end

  def attributes(totals)
    {
      name: @source_params[:name].presence || @source_class.default_import_name,
      data_type: @provider,
      source_type: 'api',
      source_provider: @provider,
      import_types: import_types,
      initiated_by: @initiated_by,
      access_token: @access_token,
      source_metadata: @source_class.source_metadata(@source_params),
      stats: initial_stats(totals)
    }
  end

  def import_types
    return DataImports::Importer::DEFAULT_IMPORT_TYPES unless @source_params.key?(:import_types)

    Array(@source_params[:import_types]).compact_blank
  end

  def initial_stats(totals)
    {
      'contacts' => { 'imported' => 0, 'skipped' => 0 },
      'conversations' => { 'imported' => 0, 'skipped' => 0 },
      'messages' => { 'imported' => 0, 'skipped' => 0 },
      'errors' => { 'count' => 0 }
    }.tap do |stats|
      totals.each { |type, total| stats[type]['total'] = total unless total.nil? }
    end
  end

  def active_import?
    @account.data_imports.active_integrations.exists?
  end
end
