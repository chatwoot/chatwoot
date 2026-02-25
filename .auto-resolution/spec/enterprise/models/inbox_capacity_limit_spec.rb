require 'rails_helper'

RSpec.describe InboxCapacityLimit, type: :model do
  let(:account) { create(:account) }
  let(:policy) { create(:agent_capacity_policy, account: account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'validations' do
    subject { create(:inbox_capacity_limit, agent_capacity_policy: policy, inbox: inbox) }

    it { is_expected.to validate_presence_of(:conversation_limit) }
    it { is_expected.to validate_numericality_of(:conversation_limit).is_greater_than(0).only_integer }
    it { is_expected.to validate_uniqueness_of(:inbox_id).scoped_to(:agent_capacity_policy_id) }
  end

  describe 'uniqueness constraint' do
    it 'prevents duplicate inbox limits for the same policy' do
      create(:inbox_capacity_limit, agent_capacity_policy: policy, inbox: inbox)
      duplicate = build(:inbox_capacity_limit, agent_capacity_policy: policy, inbox: inbox)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:inbox_id]).to include('has already been taken')
    end

    it 'allows the same inbox in different policies' do
      other_policy = create(:agent_capacity_policy, account: account)
      create(:inbox_capacity_limit, agent_capacity_policy: policy, inbox: inbox)

      different_policy_limit = build(:inbox_capacity_limit, agent_capacity_policy: other_policy, inbox: inbox)
      expect(different_policy_limit).to be_valid
    end
  end
end
