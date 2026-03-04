# frozen_string_literal: true

# Runs daily via sidekiq-cron to expire trials that have ended.
# Downgrades accounts to the Free plan when their trial period is over
# and they haven't upgraded to a paid subscription.
class Saas::ExpireTrialsJob < ApplicationJob
  queue_as :low

  def perform
    Saas::Subscription.where(status: :trialing)
                      .where('trial_end < ?', Time.current)
                      .includes(:account, :plan)
                      .find_each do |subscription|
      downgrade_to_free(subscription)
    end
  end

  private

  def downgrade_to_free(subscription)
    account = subscription.account
    free_plan = Saas::Plan.active.where(price_cents: 0).first

    if free_plan
      subscription.update!(
        plan: free_plan,
        status: :active,
        trial_end: nil
      )
      account.update!(limits: {
                        agents: free_plan.agent_limit,
                        inboxes: free_plan.inbox_limit
                      })
    else
      # No free plan exists — just cancel
      subscription.update!(status: :canceled)
      account.update!(limits: {})
    end

    Rails.logger.info("[Saas] Trial expired — downgraded account #{account.id} to #{free_plan&.name || 'canceled'}")
  end
end
