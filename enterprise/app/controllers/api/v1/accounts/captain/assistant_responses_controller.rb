class Api::V1::Accounts::Captain::AssistantResponsesController < Api::V1::Accounts::BaseController
  before_action -> { check_authorization(Captain::Assistant) }

  before_action :set_current_page, only: [:index]
  before_action :set_assistant, only: [:create, :update]
  before_action :set_responses, except: [:create]
  before_action :set_response, only: [:show, :update, :destroy, :drilldown]

  RESULTS_PER_PAGE = 25

  def index
    filtered_query = apply_filters(@responses)
    @responses_count = filtered_query.count
    @responses = filtered_query.page(@current_page).per(RESULTS_PER_PAGE)
    set_response_usage_counts if can_view_drilldown?
  end

  def show; end

  def drilldown
    return head :not_found unless @response.documentable_type == 'User'

    render json: Captain::ConversationUsageBuilder.new(@response, drilldown_params, usage_column: :used_faq_ids).build
  end

  def create
    @response = Current.account.captain_assistant_responses.new(response_params.except(:assistant_id))
    @response.assistant = @assistant
    @response.documentable = Current.user
    @response.save!
  end

  def update
    @response.assistant = @assistant if response_params.key?(:assistant_id)
    @response.update!(response_params.except(:assistant_id))
  end

  def destroy
    @response.destroy
    head :no_content
  end

  private

  def set_response_usage_counts
    user_created_responses = @responses.select { |response| response.documentable_type == 'User' }
    @response_usage_counts = Captain::ConversationUsageBuilder.conversation_counts(
      user_created_responses,
      usage_column: :used_faq_ids
    )
  end

  def can_view_drilldown?
    policy(Captain::Assistant).drilldown?
  end

  def drilldown_params
    params.permit(:page, :per_page)
  end

  def apply_filters(base_query)
    base_query = base_query.where(assistant_id: permitted_params[:assistant_id]) if permitted_params[:assistant_id].present?

    if permitted_params[:document_id].present?
      base_query = base_query.where(
        documentable_id: permitted_params[:document_id],
        documentable_type: 'Captain::Document'
      )
    end

    if permitted_params[:search].present?
      search_term = "%#{permitted_params[:search]}%"
      base_query = base_query.where(
        'question ILIKE :search OR answer ILIKE :search',
        search: search_term
      )
    end

    base_query
  end

  def set_assistant
    @assistant = Current.account.captain_assistants.find_by(id: response_params[:assistant_id])
  end

  def set_responses
    @responses = Current.account.captain_assistant_responses.includes(:assistant, :documentable).ordered
  end

  def set_response
    @response = @responses.find(permitted_params[:id])
  end

  def set_current_page
    @current_page = permitted_params[:page] || 1
  end

  def permitted_params
    params.permit(:id, :assistant_id, :page, :document_id, :account_id, :search)
  end

  def response_params
    params.require(:assistant_response).permit(
      :question,
      :answer,
      :assistant_id
    )
  end
end
