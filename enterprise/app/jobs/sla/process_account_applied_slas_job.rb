class Sla::ProcessAccountAppliedSlasJob < ApplicationJob
  queue_as :medium

  def perform(account)
    missed_slas = []

    account.applied_slas.where(sla_status: %w[active active_with_misses]).includes(:conversation, :sla_policy).each do |applied_sla|
      Sla::EvaluateAppliedSlaService.new(applied_sla: applied_sla).perform
      applied_sla.reload
      missed_slas << applied_sla if applied_sla.status == :missed || applied_sla.status == :active_with_misses
    end

    notify_missed_slas(missed_slas, account)
  end

  def notify_missed_slas(missed_slas, account)
    # notify_users = account.administrators
  end
end
