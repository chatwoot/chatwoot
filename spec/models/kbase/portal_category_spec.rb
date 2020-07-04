require 'rails_helper'

RSpec.describe Kbase::PortalCategory, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:portal_id) }
    it { is_expected.to validate_presence_of(:category_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:portal) }
    it { is_expected.to belong_to(:category) }
  end
end
