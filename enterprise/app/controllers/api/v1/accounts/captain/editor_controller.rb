class Api::V1::Accounts::Captain::EditorController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  EVENT_SERVICE_MAP = {
    'fix_spelling_grammar' => Captain::RewriteService,
    'casual' => Captain::RewriteService,
    'professional' => Captain::RewriteService,
    'friendly' => Captain::RewriteService,
    'confident' => Captain::RewriteService,
    'straightforward' => Captain::RewriteService,
    'improve' => Captain::RewriteService,
    'summarize' => Captain::SummaryService,
    'reply_suggestion' => Captain::ReplySuggestionService,
    'label_suggestion' => Captain::LabelSuggestionService
  }.freeze

  def process_event
    service_class = EVENT_SERVICE_MAP[params[:event]['name']]
    return render json: { error: 'Unknown event' }, status: :unprocessable_entity unless service_class

    result = service_class.new(
      account: Current.account,
      event: params[:event]
    ).perform

    if result.nil?
      render json: { message: nil }
    elsif result[:error]
      render json: { error: result[:error] }, status: :unprocessable_entity
    else
      render json: { message: result[:message] }
    end
  end

  private

  def check_authorization
    authorize(:'captain/editor')
  end
end
