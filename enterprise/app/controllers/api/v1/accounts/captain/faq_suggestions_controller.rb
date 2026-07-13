class Api::V1::Accounts::Captain::FaqSuggestionsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }
  before_action :set_suggestions
  before_action :set_suggestion, except: [:index]

  RESULTS_PER_PAGE = 25

  def index
    @current_page = permitted_params[:page] || 1
    filtered_query = apply_filters(@suggestions)
    @suggestions_count = filtered_query.count
    @suggestions = filtered_query.page(@current_page).per(RESULTS_PER_PAGE)
  end

  def show
    @observations = @suggestion.observations
                               .where(conversation_id: accessible_conversations.select(:id))
                               .includes(:conversation)
  end

  def update
    raise ActiveRecord::RecordNotFound unless @suggestion.open?

    @suggestion.update!(suggestion_params)
  end

  def approve
    attributes = params[:faq_suggestion].present? ? suggestion_params : {}
    @response = Captain::FaqSuggestionApprovalService.new(@suggestion, attributes).perform
  end

  def dismiss
    raise ActiveRecord::RecordNotFound unless @suggestion.open?

    @suggestion.dismissed!
  end

  private

  def apply_filters(base_query)
    base_query = base_query.where(assistant_id: permitted_params[:assistant_id]) if permitted_params[:assistant_id].present?
    base_query = base_query.where(status: permitted_params[:status]) if permitted_params[:status].present?

    if permitted_params[:search].present?
      search_term = "%#{permitted_params[:search]}%"
      base_query = base_query.where('question ILIKE :search OR answer ILIKE :search', search: search_term)
    end

    base_query
  end

  def set_suggestions
    @suggestions = Current.account.captain_faq_suggestions.includes(:assistant).ordered
  end

  def set_suggestion
    @suggestion = @suggestions.find(permitted_params[:id])
  end

  def accessible_conversations
    Conversations::PermissionFilterService.new(Current.account.conversations, Current.user, Current.account).perform
  end

  def permitted_params
    params.permit(:id, :assistant_id, :page, :status, :search)
  end

  def suggestion_params
    params.require(:faq_suggestion).permit(:question, :answer)
  end
end
