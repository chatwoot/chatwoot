class Api::V1::Accounts::Synapseos::AgentMetricsController < Api::V1::Accounts::BaseController
  before_action :ensure_administrator
  before_action :validate_agent_slug, only: %i[show usage]

  def index
    slugs = ::Synapseos::AgentResolver::SLUGS.select do |slug|
      ::Synapseos::AgentResolver.bots_for_slug(Current.account, slug).exists?
    end

    render json: {
      slugs: slugs,
      agents: slugs.map { |s| agent_descriptor(s) }
    }
  end

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

  def usage
    render json: ::Synapseos::AgentMetricsQuery.usage_for_agent(
      account: Current.account,
      slug: params[:agent_slug]
    )
  end

  private

  def ensure_administrator
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end

  def agent_descriptor(slug)
    {
      slug: slug,
      display_name: ::Synapseos::AgentResolver.display_name(slug),
      role_label: ::Synapseos::AgentResolver.role_label(slug)
    }
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
