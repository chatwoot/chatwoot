class Api::V1::Accounts::KnowledgeBasesController < Api::V1::Accounts::BaseController
  before_action :fetch_knowledge_base, only: [:show, :update, :destroy]

  def index
    @knowledge_bases = Current.account.knowledge_bases.includes(files_attachments: :blob)
    render json: knowledge_bases_with_files
  end

  def show
    render json: knowledge_base_response(@knowledge_base)
  end

  def create
    @knowledge_base = Current.account.knowledge_bases.new(knowledge_base_params)

    if @knowledge_base.save
      process_attachments if has_file_attachment?
      render json: knowledge_base_response(@knowledge_base), status: :created
    else
      render json: @knowledge_base.errors, status: :unprocessable_entity
    end
  end

  def update
    if @knowledge_base.update(knowledge_base_params)
      process_attachments if has_file_attachment?
      render json: knowledge_base_response(@knowledge_base)
    else
      render json: @knowledge_base.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @knowledge_base.destroy!
    head :ok
  end

  private

  def fetch_knowledge_base
    @knowledge_base = Current.account.knowledge_bases.find_by(id: params[:id])
  end

  def knowledge_base_params
    params.require(:knowledge_base).permit(:name, :source_type, :url)
  end

  def has_file_attachment?
    params[:file_blob_id].present?
  end

  def process_attachments
    return unless params[:file_blob_id]

    blob = ActiveStorage::Blob.find_by(id: params[:file_blob_id])
    @knowledge_base.files.attach(blob) if blob
  end

  def knowledge_bases_with_files
    @knowledge_bases.map do |kb|
      kb.as_json.merge(files: kb.file_base_data)
    end
  end

  def knowledge_base_response(kb)
    kb.as_json.merge(files: kb.file_base_data)
  end
end