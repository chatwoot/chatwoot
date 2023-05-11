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

  describe '#with_account' do
    context 'when you delete the account' do
      it 'deletes the sla_policy' do
        perform_enqueued_jobs do
          account.destroy!
        end
        expect(described_class.count).to eq 0
      end
    end
  end
end
