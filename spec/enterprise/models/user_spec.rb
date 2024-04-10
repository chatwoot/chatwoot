# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let(:user) { create(:user) }

  describe 'audit log' do
    context 'when user is created' do
      it 'has no associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'User', action: 'create').count).to eq 0
      end
    end
  end
end
