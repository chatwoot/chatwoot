class ProcessSlaJob < ApplicationJob
  queue_as :high

  def perform(applied_sla)
    EvaluateSlaService.new(applied_sla: applied_sla).perform
  end
end
