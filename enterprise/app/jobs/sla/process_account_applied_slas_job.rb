class Sla::ProcessAccountAppliedSlasJob < ApplicationJob
  queue_as :medium

  def perform(account)
    missed_slas = []

    account.applied_slas.where(sla_status: %w[active active_with_misses]).includes(:conversation, :sla_policy).each do |applied_sla|
      Sla::EvaluateAppliedSlaService.new(applied_sla: applied_sla).perform
      applied_sla.reload
      missed_slas << applied_sla if applied_sla.status == :missed || applied_sla.status == :active_with_misses
    end

    user_sla_map = build_user_sla_map(missed_slas)
    notify_users(user_sla_map, account)
  end

  def build_user_sla_map(missed_slas)
    user_sla_map = {}

    missed_slas.each do |applied_sla|
      # get all participants of the conversation
      users_to_notify = applied_sla.conversation.conversation_participants.map(&:user)
      assignee = applied_sla.conversation.assignee

      users_to_notify.each do |user|
        user_sla_map[user] ||= []
        user_sla_map[user] << applied_sla
      end

      if assignee.present?
        user_sla_map[assignee] ||= []
        user_sla_map[assignee] << applied_sla
      end
    end

    user_sla_map
  end

  def notify_users(user_sla_map, account)
    admins = account.administrators

    user_sla_map.each do |user, slas|
      puts "Notifying user #{user.id} and #{admins.count} admins about #{slas.count} missed SLAs"
    end
  end
end
