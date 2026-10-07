class Sla::ProcessAppliedSlaJob < ApplicationJob
  queue_as :medium

  def perform(applied_sla)
    # This job can already be queued when a plan is downgraded, so re-check before evaluating.
    return unless applied_sla.account.feature_enabled?('sla')

    Sla::EvaluateAppliedSlaService.new(applied_sla: applied_sla).perform
  end
end
