# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Macro do
  let(:account) { create(:account) }
  let!(:macro) { create(:macro, account: account) }

  describe 'audit log' do
    context 'when macro is created' do
      it 'has associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'Macro', action: 'create').count).to eq 1
      end
    end

    context 'when macro is updated' do
      it 'has associated audit log created' do
        macro.update!(name: 'awesome macro')
        expect(Audited::Audit.where(auditable_type: 'Macro', action: 'update').count).to eq 1
      end
    end

    context 'when macro is deleted' do
      it 'has associated audit log created' do
        macro.destroy!
        expect(Audited::Audit.where(auditable_type: 'Macro', action: 'destroy').count).to eq 1
      end
    end
  end
end
