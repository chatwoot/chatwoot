class AccountSlaJob < ApplicationJob
  queue_as :medium

  def perform(account)
    AppliedSla.includes(:conversation, :sla_policy).where(account_id: account.id, sla_status: 'active').each do |applied_sla|
      ProcessSlaJob.perform(applied_sla)
    end
  end
end
