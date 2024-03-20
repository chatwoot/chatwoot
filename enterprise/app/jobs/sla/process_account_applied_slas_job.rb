class Sla::ProcessAccountAppliedSlasJob < ApplicationJob
  queue_as :medium

  def perform(account)
    account.applied_slas.where.not(sla_status: 'hit').each do |applied_sla|
      # only proccess applied sla if the conversation is not resolved
      next if applied_sla.conversation.resolved?

      Sla::ProcessAppliedSlaJob.perform_later(applied_sla)
    end
  end
end
