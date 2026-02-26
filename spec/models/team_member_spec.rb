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
require 'rails_helper'

RSpec.describe TeamMember do
  describe 'associations' do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:user) }
  end
end
