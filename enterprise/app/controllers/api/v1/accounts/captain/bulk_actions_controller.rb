class Api::V1::Accounts::Captain::BulkActionsController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action -> { check_authorization(Captain::Assistant) }
  before_action :validate_params
  before_action :type_matches?

  MODEL_TYPE = ['AssistantResponse'].freeze

  def create
    @responses = process_bulk_action
  end

  private

  def validate_params
    return if params[:type].present? && params[:ids].present? && params[:fields].present?

    render json: { success: false }, status: :unprocessable_entity
  end

  def type_matches?
    return false if MODEL_TYPE.include?(params[:type])

    render json: { success: false }, status: :unprocessable_entity
  end

  def process_bulk_action
    case params[:type]
    when 'AssistantResponse'
      handle_assistant_responses
    end
  end

  def handle_assistant_responses
    responses = Current.account.captain_assistant_responses.where(id: params[:ids])
    return unless responses.exists?

    case params[:fields][:status]
    when 'approve'
      responses.pending.update!(status: 'approved')
      responses
    when 'delete'
      responses.destroy_all
      []
    end
  end

  def permitted_params
    params.permit(:type, ids: [], fields: [:status])
  end
end
