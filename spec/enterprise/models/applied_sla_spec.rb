require 'rails_helper'

RSpec.describe AppliedSla, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:sla_policy) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
  end

  describe 'validates_factory' do
    it 'creates valid applied sla policy object' do
      applied_sla = create(:applied_sla)
      expect(applied_sla.sla_status).to eq 'active'
    end
  end
end
