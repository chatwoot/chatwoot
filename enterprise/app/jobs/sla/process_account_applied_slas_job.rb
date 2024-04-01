class Sla::ProcessAccountAppliedSlasJob < ApplicationJob
  queue_as :medium

  def perform(account)
    account.applied_slas.where(sla_status: 'active').each do |applied_sla|
      Sla::ProcessAppliedSlaJob.perform_later(applied_sla)
    end
  end
end
