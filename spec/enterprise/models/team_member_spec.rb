# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamMember, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let!(:team_member) { create(:team_member, user: user, team: team) }

  describe 'audit log' do
    context 'when team member is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'TeamMember', action: 'create').count).to eq(2)
      end

      it 'has user_id in audited_changes matching user.id' do
        audit_log = Audited::Audit.find_by(auditable_type: 'TeamMember', action: 'create')
        expect(audit_log.audited_changes['user_id']).to eq(user.id)
      end
    end

    context 'when team member is destroyed' do
      it 'has associated audit log created' do
        team_member.destroy
        expect(Audited::Audit.where(auditable_type: 'TeamMember', action: 'destroy').count).to eq(1)
      end
    end
  end
end
