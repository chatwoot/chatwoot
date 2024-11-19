require 'rails_helper'

RSpec.describe TeamMember do
  describe 'associations' do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:user) }
  end
end
