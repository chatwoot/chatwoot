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
    ensure_import_slot!

    totals = validate_source
    blob = upload_file if @provider == 'csv'
    data_import = @account.with_lock do
      ensure_import_slot!

      @account.data_imports.new(attributes(totals)).tap do |record|
        record.assign_active_import_run_id
        record.import_file.attach(blob) if blob
        record.save!
      end
    end
    @source_class.import_job_class.perform_later(data_import, data_import.active_import_run_id)
    data_import
  ensure
    purge_unattached_blob(blob)
  end

  private

  def purge_unattached_blob(blob)
    blob.purge_later if blob && !blob.attachments.exists?
  end

  def validate_source
    DataImports::Source.validate_source(@provider, @source_params, import_types)
  end

  def upload_file
    file = @source_params.fetch(:import_file)
    ActiveStorage::Blob.create_and_upload!(io: file.tempfile, filename: file.original_filename, content_type: 'text/csv')
  end

  def attributes(totals)
    {
      name: @source_params[:name].presence || @source_class.default_import_name,
      data_type: @provider == 'csv' ? 'contacts' : @provider,
      source_type: @provider == 'csv' ? 'file' : 'api',
      source_provider: @provider,
      import_types: import_types,
      initiated_by: @initiated_by,
      access_token: @access_token,
      source_metadata: @source_class.source_metadata(@source_params),
      stats: initial_stats(totals)
    }
  end

  def import_types
    return DataImports::Source.import_types(@provider) unless @source_params.key?(:import_types)

    @source_params[:import_types]
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

  def ensure_import_slot!
    raise ArgumentError, 'Another data import is already in progress.' if @account.data_imports.active_imports.exists?
  end
end
