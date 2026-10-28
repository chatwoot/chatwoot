class Sla::ProcessAccountAppliedSlasJob < ApplicationJob
  queue_as :medium

  def perform(account)
    # The scheduler filters on the feature, but this job can already be queued when a plan is downgraded.
    return unless account.feature_enabled?('sla')

    account.applied_slas.with_sla_applicable_conversation.where(sla_status: %w[active active_with_misses]).each do |applied_sla|
      Sla::ProcessAppliedSlaJob.perform_later(applied_sla)
    end
  end
end
