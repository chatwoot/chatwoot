class RemoveOrphanInboxMembersFromInboxes < ActiveRecord::Migration[6.0]
  def change
    Account.all.map do |account|
      user_ids = account.users.all.map(&:id)
      inboxes = account.inboxes
      inboxes.each do |inbox|
        inbox.inbox_members.each do |inbox_member|
          inbox_member.destroy! unless user_ids.include?(inbox_member.user_id)
        end
      end
    end
  end
end
