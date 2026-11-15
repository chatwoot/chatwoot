# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let!(:user) { create(:user) }

  describe 'before validation for pricing plans' do
    let!(:existing_user) { create(:user) }
    let(:new_user) { build(:user) }

    context 'when pricing plan is not premium' do
      before do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('community')
        allow(ChatwootHub).to receive(:pricing_plan_quantity).and_return(0)
      end

      it 'does not add an error to the user' do
        new_user.valid?
        expect(new_user.errors[:base]).to be_empty
      end
    end

    context 'when pricing plan is premium' do
      before do
        allow(ChatwootHub).to receive(:pricing_plan).and_return('premium')
      end

      context 'when the user limit is reached' do
        it 'adds an error when trying to create a user' do
          allow(ChatwootHub).to receive(:pricing_plan_quantity).and_return(1)
          new_user.valid?
          expect(new_user.errors[:base]).to include('User limit reached. Please purchase more licenses from super admin')
        end

        it 'will not add error when trying to update a existing user' do
          allow(ChatwootHub).to receive(:pricing_plan_quantity).and_return(1)
          existing_user.update(name: 'new name')
          # since there is user and existing user, we are already over limits
          existing_user.valid?
          expect(existing_user.errors[:base]).to be_empty
        end
      end

      context 'when the user limit is not reached' do
        it 'does not add an error to the user' do
          allow(ChatwootHub).to receive(:pricing_plan_quantity).and_return(3)
          new_user.valid?
          expect(user.errors[:base]).to be_empty
        end
      end
    end
  end

  describe 'audit log' do
    before do
      create(:user)
    end

    context 'when user is created' do
      it 'has no associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'User', action: 'create').count).to eq 0
      end
    end
  end

  describe 'device trust version' do
    let(:user) { create(:user, password: 'Password1!') }

    it 'defaults to zero' do
      expect(user.device_trust_version).to eq(0)
    end

    it 'bumps when the password changes' do
      expect { user.update!(password: 'NewPassword1!') }.to change { user.reload.device_trust_version }.by(1)
    end

    it 'bumps when the email actually changes (post-confirmation)' do
      user.skip_reconfirmation!
      expect { user.update!(email: 'changed@example.com') }.to change { user.reload.device_trust_version }.by(1)
    end

    it 'does not bump on unrelated changes' do
      expect { user.update!(name: 'New Name') }.not_to(change { user.reload.device_trust_version })
    end

    it 'clears the device verification challenge budget on a password change' do
      key = format(Redis::RedisKeys::DEVICE_VERIFICATION_ISSUANCE, user_id: user.id)
      Redis::Alfred.setex(key, '5', 1.hour)
      expect { user.update!(password: 'NewPassword1!') }.to change { Redis::Alfred.get(key) }.to(nil)
    end

    it 'does not fail the credential change when the budget reset errors' do
      allow(DeviceVerification).to receive(:reset_issuance_budget).and_raise(StandardError, 'redis down')

      expect { user.update!(password: 'NewPassword1!') }.not_to raise_error
      expect(user.reload.device_trust_version).to eq(1)
    end
  end
end
