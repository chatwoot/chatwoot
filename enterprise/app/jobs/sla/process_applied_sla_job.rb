class Sla::ProcessAppliedSlaJob < ApplicationJob
  queue_as :medium

  def perform(applied_sla)
    Sla::EvaluateAppliedSlaService.new(applied_sla: applied_sla).perform
  end
end
