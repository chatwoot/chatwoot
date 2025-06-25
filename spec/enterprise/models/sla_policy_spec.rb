require 'rails_helper'

RSpec.describe SlaPolicy, type: :model do
  include ActiveJob::TestHelper
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validates_factory' do
    it 'creates valid sla policy object' do
      sla_policy = create(:sla_policy)
      expect(sla_policy.name).to eq 'sla_1'
    end
  end
end
