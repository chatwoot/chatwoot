require 'rails_helper'

RSpec.describe PortalMember do
  describe 'associations' do
    it { is_expected.to belong_to(:portal) }
    it { is_expected.to belong_to(:user) }
  end
end
