require 'rails_helper'

RSpec.describe Category, type: :model do
  context 'with validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:portal) }
    it { is_expected.to have_many(:folders) }
    it { is_expected.to have_many(:articles) }
  end
end
