# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InboxMember, type: :model do
  let(:user) { create(:user) }
  let!(:inbox_member) { create(:inbox_member, user: user) }

  describe 'audit log' do
    context 'when inbox member is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'InboxMember', action: 'create').count).to eq(2)
      end

      it 'has user_id in audited_changes matching user.id' do
        audit_log = Audited::Audit.find_by(auditable_type: 'InboxMember', action: 'create')
        expect(audit_log.audited_changes['user_id']).to eq(user.id)
      end
    end

    context 'when inbox member is destroyed' do
      it 'has associated audit log created' do
        inbox_member.destroy
        expect(Audited::Audit.where(auditable_type: 'InboxMember', action: 'destroy').count).to eq(1)
      end
    end
  end
end
