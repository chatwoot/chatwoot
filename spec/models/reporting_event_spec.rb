require 'rails_helper'

RSpec.describe ReportingEvent, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:value) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inbox).optional }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:conversation).optional }
  end
end
