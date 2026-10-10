require 'rails_helper'

RSpec.describe AssignmentPolicy do
  let(:account) { create(:account) }

  it 'accepts an eligible role from its own account' do
    role = create(:custom_role, account: account)
    policy = build(:assignment_policy, account: account, eligible_custom_role: role, business_hours_only: true,
                                       conversation_priority: :latest_customer_message)
    expect(policy).to be_valid
  end

  it 'rejects an eligible role belonging to another account' do
    policy = build(:assignment_policy, account: account, eligible_custom_role: create(:custom_role))
    expect(policy).not_to be_valid
    expect(policy.errors[:eligible_custom_role]).to be_present
  end

  describe 'enum values' do
    let(:assignment_policy) { create(:assignment_policy, account: account) }

    describe 'assignment_order' do
      it 'can be set to balanced' do
        assignment_policy.update!(assignment_order: :balanced)
        expect(assignment_policy.assignment_order).to eq('balanced')
        expect(assignment_policy.round_robin?).to be false
        expect(assignment_policy.balanced?).to be true
      end
    end
  end
end
