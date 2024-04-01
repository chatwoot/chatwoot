class Sla::ProcessAccountAppliedSlasJob < ApplicationJob
  queue_as :medium

  def perform(account)
    account.applied_slas.where(sla_status: %w[active active_with_misses]).each do |applied_sla|
      Sla::EvaluateAppliedSlaService.new(applied_sla: applied_sla).perform
    end
  end
end
