require 'rails_helper'

RSpec.describe LinkedCategory, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:linked_category) }
  end
end
