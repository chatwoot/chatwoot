class Api::V1::Accounts::Aiagent::DocumentsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Aiagent::Topic) }

  before_action :set_current_page, only: [:index]
  before_action :set_documents, except: [:create]
  before_action :set_document, only: [:show, :destroy]
  before_action :set_topic, only: [:create]
  RESULTS_PER_PAGE = 25

  def index
    base_query = @documents
    base_query = base_query.where(topic_id: permitted_params[:topic_id]) if permitted_params[:topic_id].present?

    @documents_count = base_query.count
    @documents = base_query.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    return render_could_not_create_error('Missing Topic') if @topic.nil?

    @document = @topic.documents.build(document_params)
    @document.save!
  rescue Aiagent::Document::LimitExceededError => e
    render_could_not_create_error(e.message)
  end

  def destroy
    @document.destroy
    head :no_content
  end

  private

  def set_documents
    @documents = Current.account.aiagent_documents.includes(:topic).ordered
  end

  def set_document
    @document = @documents.find(permitted_params[:id])
  end

  def set_topic
    @topic = Current.account.aiagent_topics.find_by(id: document_params[:topic_id])
  end

  def set_current_page
    @current_page = permitted_params[:page] || 1
  end

  def permitted_params
    params.permit(:topic_id, :page, :id, :account_id)
  end

  def document_params
    params.require(:document).permit(:name, :external_link, :topic_id)
  end
end
