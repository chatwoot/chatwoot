# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamMember, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let!(:team_member) { create(:team_member, user: user, team: team) }

  describe 'audit log' do
    context 'when team member is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable: team_member, action: 'create').count).to eq(1)
      end

      it 'has user_id in audited_changes matching user.id' do
        audit_log = Audited::Audit.find_by(auditable: team_member, action: 'create')
        expect(audit_log.audited_changes['user_id']).to eq(user.id)
      end
    end

    context 'when team member is destroyed' do
      it 'has associated audit log created' do
        team_member.destroy
        audit_log = Audited::Audit.find_by(auditable: team_member, action: 'destroy')
        expect(audit_log).to be_present
        expect(audit_log.audited_changes['team_id']).to eq(team.id)
      end
    end
  end
end
