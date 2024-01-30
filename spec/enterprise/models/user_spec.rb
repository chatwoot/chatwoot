# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let(:user) { create(:user) }

  describe 'before validation for pricing plans' do
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
        it 'adds an error to the user' do
          allow(ChatwootHub).to receive(:pricing_plan_quantity).and_return(1)
          user.valid?
          expect(user.errors[:base]).to include('User limit reached. Please purchase more licenses from super admin')
        end
      end

      context 'when the user limit is not reached' do
        it 'does not add an error to the user' do
          allow(ChatwootHub).to receive(:pricing_plan_quantity).and_return(2)
          user.valid?
          expect(user.errors[:base]).to be_empty
        end
      end
    end
  end

  describe 'audit log' do
    context 'when user is created' do
      it 'has no associated audit log created' do
        expect(Audited::Audit.where(auditable_type: 'User', action: 'create').count).to eq 0
      end
    end
  end
end
