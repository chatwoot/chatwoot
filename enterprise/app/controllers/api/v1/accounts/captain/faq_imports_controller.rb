class Api::V1::Accounts::Captain::FaqImportsController < Api::V1::Accounts::BaseController
  DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE_MB = 40

  before_action -> { authorize(Captain::Assistant, :create?) }
  before_action :set_assistant
  before_action :set_faq_import, only: [:confirm, :invalid_rows]

  def create
    return render json: { error: 'Choose a CSV file.' }, status: :unprocessable_content if params[:file].blank?
    return render_file_too_large if uploaded_file_too_large?

    active_import = @assistant.faq_imports.preparing.first
    if active_import
      recover_if_stalled(active_import)
      return render_active_import_error
    end

    content = params[:file].read
    rows = Captain::FaqImports::Parser.new(assistant: @assistant, content: content).perform
    faq_import = create_preview!(rows)
    Captain::FaqImports::CleanupJob.set(wait: 24.hours).perform_later(faq_import)

    render json: serialize(faq_import), status: :created
  rescue Captain::FaqImports::Parser::InvalidCsvError => e
    render json: { error: e.message }, status: :unprocessable_content
  rescue Captain::FaqImport::ActiveImportError, ActiveRecord::RecordNotUnique
    render_active_import_error
  end

  def latest
    faq_import = @assistant.faq_imports.confirmed.latest_first.first
    recover_if_stalled(faq_import)
    render json: faq_import ? serialize(faq_import) : nil
  end

  def confirm
    @assistant.with_lock do
      @faq_import.reload.confirm!(params[:overwrite_row_numbers])
    end
    Captain::FaqImports::ProcessJob.perform_later(@faq_import)
    render json: serialize(@faq_import), status: :accepted
  rescue Captain::FaqImport::InvalidStateError, ActiveRecord::RecordNotFound
    render json: { error: 'This import can no longer be confirmed.' }, status: :unprocessable_content
  end

  def invalid_rows
    csv = CSVSafe.generate do |output|
      output << %w[question answer error]
      @faq_import.invalid_rows.each do |row|
        output << [row['question'], row['answer'], row['error']]
      end
    end

    send_data csv, filename: "invalid-#{@faq_import.original_filename}", type: 'text/csv'
  end

  private

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end

  def set_faq_import
    @faq_import = @assistant.faq_imports.find(params[:id])
  end

  def create_preview!(rows)
    @assistant.with_lock do
      raise Captain::FaqImport::ActiveImportError if @assistant.faq_imports.preparing.exists?

      @assistant.faq_imports.preview.destroy_all
      @assistant.faq_imports.create!(preview_attributes(rows))
    end
  end

  def preview_attributes(rows)
    {
      account: Current.account,
      user: Current.user,
      original_filename: params[:file].original_filename,
      rows: rows,
      row_count: rows.length
    }
  end

  def render_active_import_error
    render json: { error: 'Another FAQ import is already active for this assistant.' }, status: :conflict
  end

  def uploaded_file_too_large?
    configured_limit = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE_MB).to_i
    configured_limit = DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE_MB unless configured_limit.positive?

    params[:file].size > configured_limit.megabytes
  end

  def render_file_too_large
    render json: { error: I18n.t('errors.upload.file_too_large') }, status: :unprocessable_content
  end

  def recover_if_stalled(faq_import)
    recovery_claimed_at = faq_import&.claim_stalled_recovery!
    Captain::FaqImports::RecoverStalledJob.perform_later(faq_import, recovery_claimed_at) if recovery_claimed_at
  end

  def serialize(faq_import)
    {
      id: faq_import.id,
      original_filename: faq_import.original_filename,
      status: faq_import.status,
      row_count: faq_import.row_count,
      invalid_row_count: faq_import.invalid_rows.count,
      created_count: faq_import.created_count,
      overwritten_count: faq_import.overwritten_count,
      skipped_count: faq_import.skipped_count,
      embedding_ready_count: faq_import.embedding_ready_count,
      embedding_failed_count: faq_import.embedding_failed_count,
      error_message: faq_import.error_message,
      rows: faq_import.preview? ? faq_import.rows : nil,
      created_at: faq_import.created_at,
      completed_at: faq_import.completed_at
    }
  end
end
