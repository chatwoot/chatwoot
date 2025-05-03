require 'rails_helper'

RSpec.describe MessageQualityScore do
  describe 'associations' do
    it { is_expected.to belong_to(:message) }
  end
end
