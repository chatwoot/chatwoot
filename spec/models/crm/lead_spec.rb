require 'rails_helper'

RSpec.describe Crm::Lead, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:crm_stage) }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to belong_to(:conversation).optional }
    it { is_expected.to belong_to(:user).optional }
  end
end
