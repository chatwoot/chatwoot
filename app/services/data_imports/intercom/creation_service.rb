class DataImports::Intercom::CreationService
  def initialize(account:, initiated_by:, source_params:)
    @account = account
    @initiated_by = initiated_by
    @source_params = source_params.symbolize_keys
    @access_token = @source_params[:access_token].to_s.strip
  end

  def perform
    return if active_import?

    totals = validate_source
    @account.with_lock do
      next if active_import?

      @account.data_imports.new(attributes(totals)).tap do |data_import|
        data_import.assign_active_intercom_import_run_id
        data_import.save!
      end
    end
  end

  private

  def validate_source
    raise ArgumentError, 'Unsupported import source.' unless @source_params[:source_provider] == 'intercom'

    DataImports::Intercom::CredentialsValidator.new(
      access_token: @access_token,
      import_types: import_types
    ).perform
  end

  def attributes(totals)
    {
      name: @source_params[:name].presence || 'Intercom import',
      data_type: 'intercom',
      source_type: 'api',
      source_provider: 'intercom',
      import_types: import_types,
      initiated_by: @initiated_by,
      access_token: @access_token,
      stats: initial_stats(totals)
    }
  end

  def import_types
    return DataImports::Intercom::Importer::DEFAULT_IMPORT_TYPES unless @source_params.key?(:import_types)

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
    @account.data_imports.active_intercom.exists?
  end
end
