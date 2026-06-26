class BackfillSanitizedTeamNames < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    Team.find_each do |team|
      sanitized = team.name.gsub(/[[:cntrl:]]/, '').strip.downcase
      next if sanitized == team.name || sanitized.blank?

      sanitized = "#{sanitized}-#{team.id}" if Team.where(account_id: team.account_id, name: sanitized).where.not(id: team.id).exists?
      team.update_column(:name, sanitized)
    end
  end

  def down
    # Original control characters are not recoverable; nothing to revert.
  end
end
