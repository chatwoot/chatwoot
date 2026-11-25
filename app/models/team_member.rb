# == Schema Information
#
# Table name: team_members
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  team_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_team_members_on_team_id              (team_id)
#  index_team_members_on_team_id_and_user_id  (team_id,user_id) UNIQUE
#  index_team_members_on_user_id              (user_id)
#
class TeamMember < ApplicationRecord
  belongs_to :user
  belongs_to :team
  validates :user_id, uniqueness: { scope: :team_id }

  after_create :add_to_linked_internal_chat_channels
  after_commit :invalidate_filtered_unread_count_visibility, on: [:create, :destroy]

  private

  def add_to_linked_internal_chat_channels
    return unless InternalChat::ChannelTeam.table_exists?

    InternalChat::ChannelTeam.where(team_id: team_id).find_each do |channel_team|
      channel_team.channel.channel_members.find_or_create_by!(user_id: user_id) { |m| m.role = :member }
    end
  end

  def invalidate_filtered_unread_count_visibility
    ::Conversations::UnreadCounts::FilteredCountInvalidator.new(team&.account).user_visibility_changed!(user_id: user_id)
  end
end

TeamMember.include_mod_with('Audit::TeamMember')
