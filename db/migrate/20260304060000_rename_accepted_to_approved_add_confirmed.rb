class RenameAcceptedToApprovedAddConfirmed < ActiveRecord::Migration[7.0]
  # Enum mapping: approved = 3 (was 'accepted'), confirmed = 6 (new)
  # Profiles in status 3 that have an accepted offer should become confirmed (6).
  def up
    execute <<~SQL.squish
      UPDATE influencer_profiles
      SET status = 6
      WHERE status = 3
        AND id IN (SELECT influencer_profile_id FROM influencer_offers WHERE status = 1)
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE influencer_profiles
      SET status = 3
      WHERE status = 6
    SQL
  end
end
