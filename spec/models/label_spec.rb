require 'rails_helper'

RSpec.describe Label, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end
end
