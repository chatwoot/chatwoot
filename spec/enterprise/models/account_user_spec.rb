# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountUser do
  describe 'audit log' do
    context 'when account user is created' do
      it 'has associated audit log created' do
        account_user = create(:account_user)
        account_user_audit_log = Audited::Audit.where(auditable_type: 'AccountUser', action: 'create').first
        expect(account_user_audit_log).to be_present
        expect(account_user_audit_log.associated).to eq(account_user.account)
      end
    end
  end
end
