require 'rails_helper'

RSpec.describe AppliedSla, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sla_policies) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:sla_policies_id) }
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:account_id) }
  end

  describe 'validates_factory' do
    it 'creates valid applied sla policy object' do
      applied_sla = create(:applied_slas)
      expect(applied_sla.status).to eq 'active'
    end
  end
end
