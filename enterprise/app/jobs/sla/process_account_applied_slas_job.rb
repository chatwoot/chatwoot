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
    notify_users(user_sla_map, account)
  end

  def build_user_sla_map(missed_slas)
    user_sla_map = {}

    missed_slas.each do |missed_sla|
      applied_sla = missed_sla[:applied_sla]
      sla_events = missed_sla[:sla_events]

      # get all participants of the conversation
      users_to_notify = applied_sla.conversation.conversation_participants.map(&:user)
      assignee = applied_sla.conversation.assignee

      users_to_notify.each do |user|
        user_sla_map[user] ||= []
        user_sla_map[user] << { sla_events: sla_events, applied_sla: applied_sla }
      end

      if assignee.present?
        user_sla_map[assignee] ||= []
        user_sla_map[assignee] << { sla_events: sla_events, applied_sla: applied_sla }
      end
    end

    user_sla_map
  end

  def notify_users(user_sla_map, account)
    admins = account.administrators

    user_sla_map.each do |user, sla_data|
      puts "Notifying user #{user.id} and #{admins.count} admins about #{sla_data.count} missed SLAs"
    end
  end
end
