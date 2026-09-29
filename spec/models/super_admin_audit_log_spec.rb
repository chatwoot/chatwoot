require 'rails_helper'

RSpec.describe SuperAdminAuditLog do
  let(:super_admin) { create(:super_admin) }
  let(:user) { create(:user) }

  it { is_expected.to validate_presence_of(:super_admin_id) }
  it { is_expected.to validate_presence_of(:action) }

  it 'retains the original staff and target IDs after either user is deleted' do
    event = described_class.create!(super_admin: super_admin, target_user: user, action: 'impersonation_started')
    staff_id = super_admin.id
    user_id = user.id

    super_admin.destroy!
    user.destroy!

    expect(event.reload).to have_attributes(super_admin_id: staff_id, target_user_id: user_id)
    expect(event.super_admin).to be_nil
    expect(event.target_user).to be_nil
  end
end
