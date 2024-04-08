class Sla::ProcessAccountAppliedSlasJob < ApplicationJob
  queue_as :medium

  def perform(account)
    missed_slas = []

    account.applied_slas.where(sla_status: %w[active active_with_misses]).includes(:conversation, :sla_policy).each do |applied_sla|
      sla_events, updated_applied_sla = Sla::EvaluateAppliedSlaService.new(applied_sla: applied_sla).perform
      if updated_applied_sla.status == :missed || updated_applied_sla.status == :active_with_misses
        missed_slas << { sla_events: sla_events,
                         applied_sla: updated_applied_sla }
      end
    end

    user_sla_map = build_user_sla_map(missed_slas)
    notify_users(user_sla_map)
  end

  def build_user_sla_map(missed_slas)
    missed_slas.each_with_object({}) do |missed_sla, user_missed_slas_map|
      applied_sla = missed_sla[:applied_sla]
      sla_events = missed_sla[:sla_events]
      conversation = applied_sla.conversation

      users_to_notify = conversation.conversation_participants.map(&:user)
      users_to_notify << conversation.assignee if conversation.assignee.present?

      users_to_notify.uniq.each do |user|
        user_missed_slas_map[user] ||= []
        user_missed_slas_map[user] += [{ sla_events: sla_events, applied_sla: applied_sla }]
      end
    end
  end

  def notify_users(user_sla_map)
    user_sla_map.each do |user, sla_data|
      puts "Notifying user #{user.id} and #{admins.count} admins about #{sla_data.count} missed SLAs"
    end
  end
end
