require 'rails_helper'

RSpec.describe RelatedCategory, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to belong_to(:related_category) }
  end
end
