class Captain::Copilot::Resources::Csat < Captain::Copilot::Resources::BaseResource
  NAME = 'csat'.freeze
  MODEL = CsatSurveyResponse
  DATE_FIELDS = %w[created_at].freeze
  FILTERS = {
    team_id: { type: 'integer', minimum: 1, description: "The conversation's team" },
    with_feedback: { type: 'boolean', description: 'true for responses with a written comment' }
  }.freeze
  SOURCES = {}.freeze
  COLUMNS = %w[Rating Agent Feedback Date].freeze
  PRELOAD = [:conversation, :assigned_agent].freeze
  EXCERPT_LENGTH = 160

  # The same permission as the CSAT report.
  def readable?
    account_user = @account.account_users.find_by(user_id: @user.id)
    account_user.present? && CsatSurveyResponsePolicy.new({ user: @user, account: @account, account_user: account_user }, CsatSurveyResponse).index?
  end

  # Limited to responses in conversations the user can open.
  def scope
    raise ArgumentError, 'You do not have permission to view CSAT responses' unless readable?

    @account.csat_survey_responses.where(conversation_id: accessible_conversations(account: @account, user: @user).select(:id))
  end

  def filter(relation, filters)
    relation = relation.where(conversation_id: @account.conversations.where(team_id: filters['team_id']).select(:id)) if filters['team_id']
    return relation if filters['with_feedback'].nil?

    filters['with_feedback'] ? relation.where.not(feedback_message: [nil, '']) : relation.where(feedback_message: [nil, ''])
  end

  def row(response)
    display_id = response.conversation.display_id
    { label: "##{display_id}", url: url("conversations/#{display_id}"),
      values: [response.rating, response.assigned_agent&.name, response.feedback_message.to_s.squish.first(EXCERPT_LENGTH),
               response.created_at.to_date] }
  end
end
