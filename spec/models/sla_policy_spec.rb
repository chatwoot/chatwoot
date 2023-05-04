require 'rails_helper'

RSpec.describe SlaPolicy, type: :model do
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

  # describe '#associations' do
  #   let!(:sla_policy) { create(:sla_policy, account: account) }

  #   context 'when you delete the author' do
  #     it 'deletes the sla_policy' do
  #       admin.destroy!
  #       expect(SlaPolicy.count).to eq(0)
  #     end
  #   end
  # end
end
