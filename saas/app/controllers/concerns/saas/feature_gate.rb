module Concerns::Saas::FeatureGate
  extend ActiveSupport::Concern

  private

  # Checks that the current account's plan includes the given feature.
  # Returns early with a 403 JSON response when the feature is absent.
  #
  # Usage:
  #   before_action -> { require_plan_feature!(:ai_agents) }
  #   before_action -> { require_plan_feature!(:voice_agents) }, only: %i[create]
  def require_plan_feature!(feature_key)
    plan = Current.account&.saas_plan
    return render_feature_unavailable unless plan&.feature_enabled?(feature_key)
  end

  # Checks that a numeric feature limit has not been exceeded.
  # `current_count` is the current usage count for the resource.
  #
  # Usage:
  #   before_action -> { require_plan_limit!(:ai_agents_limit, current_account.ai_agents.count) }, only: %i[create]
  def require_plan_limit!(feature_key, current_count)
    plan = Current.account&.saas_plan
    return render_feature_unavailable unless plan

    limit = plan.feature_limit(feature_key)
    return render_feature_unavailable if limit.nil?

    # -1 means unlimited
    return if limit == -1
    return if current_count < limit

    render json: { error: 'Limite do plano atingido para este recurso' }, status: :forbidden
  end

  def render_feature_unavailable
    render json: { error: 'Recurso não disponível no seu plano atual' }, status: :forbidden
  end
end
