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
    it { is_expected.to have_many(:conversations).dependent(:nullify) }
  end

  describe 'validates_factory' do
    it 'creates valid sla policy object' do
      sla_policy = create(:sla_policy)
      expect(sla_policy.name).to eq 'sla_1'
      expect(sla_policy.first_response_time_threshold).to eq 2000
      expect(sla_policy.description).to eq 'SLA policy for enterprise customers'
      expect(sla_policy.next_response_time_threshold).to eq 1000
      expect(sla_policy.resolution_time_threshold).to eq 3000
      expect(sla_policy.only_during_business_hours).to be false
    end
  end
end
