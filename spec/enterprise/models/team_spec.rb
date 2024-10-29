# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team do
  let(:account) { create(:account) }
  let!(:team) { create(:team, account: account) }

  describe 'audit log' do
    context 'when team is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'Team', action: 'create').count).to eq 1
      end
    end

    context 'when team is updated' do
      it 'has associated audit log created' do
        team.update(description: 'awesome team')
        expect(Audited::Audit.where(auditable_type: 'Team', action: 'update').count).to eq 1
      end
    end

    context 'when team is deleted' do
      it 'has associated audit log created' do
        team.destroy!
        expect(Audited::Audit.where(auditable_type: 'Team', action: 'destroy').count).to eq 1
      end
    end
  end
end
