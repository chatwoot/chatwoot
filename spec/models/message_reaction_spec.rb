RSpec.describe MessageReaction do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:sender).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:direction) }
    it { is_expected.to validate_presence_of(:status) }
  end
end
