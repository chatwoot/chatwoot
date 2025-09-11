class Api::V1::Accounts::KnowledgeSourceFilesController < Api::V1::Accounts::BaseController
  before_action :set_ai_agent
  before_action :validate_file_size, only: [:create]

  MAX_FILE_SIZE_MB = 5

  def create
    knowledge_source = @ai_agent.knowledge_source

    unless knowledge_source
      render json: { error: 'Knowledge source not found' }, status: :not_found
      return
    end

    if params[:file].blank?
      render json: { error: 'File is required' }, status: :unprocessable_entity
      return
    end

    create_source(knowledge_source, params[:file])
    upsert_document_store(knowledge_source)
  end

  def destroy
    knowledge_source = @ai_agent.knowledge_source
    return render json: { error: 'Knowledge source not found' }, status: :not_found if knowledge_source.nil?

    knowledge_source_file = knowledge_source.knowledge_source_files.find_by(id: params[:id])
    return render json: { error: 'Knowledge source file not found' }, status: :not_found if knowledge_source.nil?

    if knowledge_source_file.destroy
      delete_document_loader(store_id: knowledge_source.store_id, loader_id: knowledge_source_file.loader_id)
      upsert_document_store(knowledge_source) if knowledge_source.not_empty?
      # If the knowledge source is empty, we don't need to upsert the document store
      # because it will be deleted in the destroy method of the knowledge source.

      head :no_content
    else
      render json: { error: 'Failed to delete knowledge source file' }, status: :unprocessable_entity
    end
  end

  private

  def create_source(knowledge_source, file)
    document_loader = create_document_loader(knowledge_source.store_id, file)

    unless document_loader
      render json: { error: 'Failed to create document loader' }, status: :bad_gateway
      return
    end

    begin
      knowledge_source_file = knowledge_source.add_file!(file: file, document_loader: document_loader)
      render json: knowledge_source_file, status: :created
    rescue StandardError => e
      delete_document_loader(store_id: knowledge_source.store_id, loader_id: document_loader['docId'])
      render json: { error: "Failed to create knowledge source: #{e.message}" }, status: :bad_gateway
    end
  end

  def create_document_loader(store_id, file)
    file_name = formatted_file_name(file.original_filename)
    ext = File.extname(file_name).downcase

    raise "Unsupported file type: #{ext}" unless %w[.pdf .docx].include?(ext)

    loader_id = if ext == '.pdf'
                  'pdfFile'
                else
                  'docxFile'
                end

    base64_content = convert_file_to_base64(file, file_name)

    AiAgents::FlowiseService.add_document_loader(
      store_id: store_id,
      loader_id: loader_id,
      splitter_id: 'recursiveCharacterTextSplitter',
      name: file_name,
      content: base64_content
    )
  rescue StandardError => e
    Rails.logger.error("Failed to add document loader: #{e.message}")
    nil
  end

  def delete_document_loader(store_id:, loader_id:)
    AiAgents::FlowiseService.delete_document_loader(
      store_id: store_id,
      loader_id: loader_id
    )
  rescue StandardError => e
    Rails.logger.error("Failed to delete document loader: #{e.message}")
  end

  def upsert_document_store(knowledge_source)
    AiAgents::FlowiseService.upsert_document_store(knowledge_source.store_config)
  end

  def formatted_file_name(file_name)
    base_name = File.basename(file_name, '.*')
    extension = File.extname(file_name)
    sanitized_name = base_name.strip.gsub(/\s+/, '_')
    random_string = SecureRandom.alphanumeric(5)

    "#{sanitized_name}_#{random_string}#{extension}"
  end

  def convert_file_to_base64(file, file_name)
    base64 = Base64.strict_encode64(file.read)
    "data:#{file.content_type};base64,#{base64},filename:#{file_name}"
  rescue StandardError => e
    Rails.logger.error("Failed to convert file to base64: #{e.message}")
    nil
  end

  def validate_file_size
    uploaded_file = params[:file]

    if uploaded_file.nil?
      render json: { error: I18n.t('ai_agents.knowledge_source.file_size_error') }, status: :unprocessable_entity
      return
    end

    return unless uploaded_file.size > MAX_FILE_SIZE_MB.megabytes

    render json: { error: I18n.t('ai_agents.knowledge_source.file_size_error') }, status: :unprocessable_entity
  end

  def set_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'AI Agent not found' }, status: :not_found
  end
end
