class Api::V1::Accounts::Captain::FaqImportsController < Api::V1::Accounts::BaseController
  before_action -> { authorize(Captain::Assistant, :create?) }
  before_action :set_assistant
  before_action :set_faq_import, only: [:show, :confirm, :invalid_rows]

  def show
    render json: serialize(@faq_import)
  end

  def create
    return render json: { error: 'Choose a CSV file.' }, status: :unprocessable_content if params[:file].blank?

    active_import = @assistant.faq_imports.preparing.first
    if active_import
      recover_if_stalled(active_import)
      return render_active_import_error
    end

    content = params[:file].read
    rows = Captain::FaqImports::Parser.new(assistant: @assistant, content: content).perform
    faq_import = create_preview!(content, rows)
    Captain::FaqImports::CleanupJob.set(wait: 24.hours).perform_later(faq_import)

    render json: serialize(faq_import), status: :created
  rescue Captain::FaqImports::Parser::InvalidCsvError => e
    render json: { error: e.message }, status: :unprocessable_content
  rescue ActiveRecord::RecordNotUnique
    render_active_import_error
  end

  def latest
    faq_import = @assistant.faq_imports.confirmed.latest_first.first
    recover_if_stalled(faq_import)
    render json: faq_import ? serialize(faq_import) : nil
  end

  def confirm
    @faq_import.confirm!(params[:overwrite_row_numbers])
    Captain::FaqImports::ProcessJob.perform_later(@faq_import)
    render json: serialize(@faq_import), status: :accepted
  rescue Captain::FaqImport::InvalidStateError
    render json: { error: 'This import can no longer be confirmed.' }, status: :unprocessable_content
  end

  def invalid_rows
    csv = CSV.generate do |output|
      output << %w[question answer error]
      @faq_import.rows.select { |row| row['state'] == 'invalid' }.each do |row|
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

  def create_preview!(content, rows)
    @assistant.faq_imports.preview.destroy_all
    faq_import = @assistant.faq_imports.create!(preview_attributes(content, rows))
    faq_import.source_file.attach(
      io: StringIO.new(content), filename: faq_import.original_filename, content_type: 'text/csv'
    )
    faq_import
  end

  def preview_attributes(content, rows)
    {
      account: Current.account,
      user: Current.user,
      original_filename: params[:file].original_filename,
      checksum: Digest::SHA256.hexdigest(content),
      rows: rows,
      row_count: rows.length
    }
  end

  def render_active_import_error
    render json: { error: 'Another FAQ import is already active for this assistant.' }, status: :conflict
  end

  def recover_if_stalled(faq_import)
    Captain::FaqImports::RecoverStalledJob.perform_later(faq_import) if faq_import&.stalled?
  end

  def serialize(faq_import)
    {
      id: faq_import.id,
      original_filename: faq_import.original_filename,
      status: faq_import.status,
      row_count: faq_import.row_count,
      invalid_row_count: faq_import.rows.count { |row| row['state'] == 'invalid' },
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
