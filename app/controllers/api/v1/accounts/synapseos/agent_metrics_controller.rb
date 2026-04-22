class Api::V1::Accounts::Synapseos::AgentMetricsController < Api::V1::Accounts::BaseController
  before_action :ensure_administrator
  before_action :validate_agent_slug, only: :show

  def live
    render json: ::Synapseos::AgentMetricsQuery.live(account: Current.account)
  end

  def show
    render json: ::Synapseos::AgentMetricsQuery.for_agent(
      account: Current.account,
      slug: params[:agent_slug],
      since: since_param
    )
  end

  private

  def ensure_administrator
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end

  def validate_agent_slug
    return if ::Synapseos::AgentResolver::SLUGS.include?(params[:agent_slug])

    render json: { error: 'unknown agent slug' }, status: :not_found
  end

  def since_param
    return 30.days.ago if params[:since].blank?

    Time.iso8601(params[:since])
  rescue ArgumentError
    30.days.ago
  end
end
