class Agents::DestroyService
  pattr_initialize [:account!, :user!]

  def perform
    ActiveRecord::Base.transaction do
      destroy_notification_setting
      remove_user_from_teams
      remove_user_from_inboxes
    end
  end

  private

  def remove_user_from_inboxes
    inboxes = account.inboxes.all
    inbox_members = user.inbox_members.where(inbox_id: inboxes.pluck(:id))
    inbox_members.destroy_all
  end

  def remove_user_from_teams
    teams = account.teams.all
    team_members = user.team_members.where(team_id: teams.pluck(:id))
    team_members.destroy_all
  end

  def destroy_notification_setting
    setting = user.notification_settings.find_by(account_id: account.id)
    setting&.destroy!
  end
end
