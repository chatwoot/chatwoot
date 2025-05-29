class Api::V1::Accounts::Aiagent::TopicResponsesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Aiagent::Topic) }

  before_action :set_current_page, only: [:index]
  before_action :set_topic, only: [:create]
  before_action :set_responses, except: [:create]
  before_action :set_response, only: [:show, :update, :destroy]

  RESULTS_PER_PAGE = 25

  def index
    base_query = @responses
    base_query = base_query.where(topic_id: permitted_params[:topic_id]) if permitted_params[:topic_id].present?

    if permitted_params[:document_id].present?
      base_query = base_query.where(
        documentable_id: permitted_params[:document_id],
        documentable_type: 'Aiagent::Document'
      )
    end

    base_query = base_query.where(status: permitted_params[:status]) if permitted_params[:status].present?

    @responses_count = base_query.count

    @responses = base_query.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show; end

  def create
    @response = Current.account.aiagent_topic_responses.new(response_params)
    @response.documentable = Current.user
    @response.save!
  end

  def update
    @response.update!(response_params)
  end

  def destroy
    @response.destroy
    head :no_content
  end

  private

  def set_topic
    @topic = Current.account.aiagent_topics.find_by(id: params[:topic_id])
  end

  def set_responses
    @responses = Current.account.aiagent_topic_responses.includes(:topic, :documentable).ordered
  end

  def set_response
    @response = @responses.find(permitted_params[:id])
  end

  def set_current_page
    @current_page = permitted_params[:page] || 1
  end

  def permitted_params
    params.permit(:id, :topic_id, :page, :document_id, :account_id, :status)
  end

  def response_params
    params.require(:topic_response).permit(
      :question,
      :answer,
      :topic_id,
      :status
    )
  end
end
