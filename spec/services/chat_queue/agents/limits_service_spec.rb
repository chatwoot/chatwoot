require 'rails_helper'

RSpec.describe ChatQueue::Agents::LimitsService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account) }
  let(:service) { described_class.new(account: account) }
  let!(:account_user) { AccountUser.find_or_create_by!(account: account, user: agent) }

  describe '#limit_for' do
    context 'when the agent has an active chat limit' do
      before do
        account_user.update!(active_chat_limit_enabled: true, active_chat_limit: 5)
        account.update!(active_chat_limit_enabled: false, active_chat_limit_value: nil)
      end

      it 'returns the agent specific limit' do
        expect(service.limit_for(agent.id)).to eq(5)
      end
    end

    context 'when the agent does not have a limit but the account has a limit' do
      before do
        account_user.update!(active_chat_limit_enabled: false, active_chat_limit: nil)
        account.update!(active_chat_limit_enabled: true, active_chat_limit_value: 10)
      end

      it 'returns the account limit' do
        expect(service.limit_for(agent.id)).to eq(10)
      end
    end

    context 'when neither the agent nor the account has a limit' do
      before do
        account_user.update!(active_chat_limit_enabled: false, active_chat_limit: nil)
        account.update!(active_chat_limit_enabled: false, active_chat_limit_value: nil)
      end

      it 'returns nil' do
        expect(service.limit_for(agent.id)).to be_nil
      end
    end

    context 'when the agent has limit disabled but account has limit enabled' do
      before do
        account_user.update!(active_chat_limit_enabled: false, active_chat_limit: 5)
        account.update!(active_chat_limit_enabled: true, active_chat_limit_value: 8)
      end

      it 'returns the account limit' do
        expect(service.limit_for(agent.id)).to eq(8)
      end
    end

    context 'when both agent and account have limits enabled' do
      before do
        account_user.update!(active_chat_limit_enabled: true, active_chat_limit: 3)
        account.update!(active_chat_limit_enabled: true, active_chat_limit_value: 10)
      end

      it 'prioritizes agent limit over account limit' do
        expect(service.limit_for(agent.id)).to eq(3)
      end

      context 'when agent limit is higher than account limit' do
        before do
          account_user.update!(active_chat_limit: 15)
        end

        it 'still returns agent limit (not the lower one)' do
          expect(service.limit_for(agent.id)).to eq(15)
        end
      end
    end

    context 'when handling unusual cases' do
      context 'when agent limit is zero' do
        before do
          account_user.update!(active_chat_limit_enabled: true, active_chat_limit: 0)
        end

        it 'returns 0 (no conversations allowed)' do
          expect(service.limit_for(agent.id)).to eq(0)
        end
      end

      context 'when account limit is zero' do
        before do
          account_user.update!(active_chat_limit_enabled: false)
          account.update!(active_chat_limit_enabled: true, active_chat_limit_value: 0)
        end

        it 'returns 0' do
          expect(service.limit_for(agent.id)).to eq(0)
        end
      end

      context 'when agent has limit enabled but value is nil' do
        before do
          account_user.update!(active_chat_limit_enabled: true, active_chat_limit: nil)
          account.update!(active_chat_limit_enabled: true, active_chat_limit_value: 10)
        end

        it 'falls back to account limit' do
          expect(service.limit_for(agent.id)).to eq(10)
        end
      end

      context 'when AccountUser record does not exist' do
        let(:other_agent) { create(:user) }

        it 'returns account limit if enabled' do
          account.update!(active_chat_limit_enabled: true, active_chat_limit_value: 7)
          expect(service.limit_for(other_agent.id)).to eq(7)
        end

        it 'returns nil if no account limit' do
          account.update!(active_chat_limit_enabled: false)
          expect(service.limit_for(other_agent.id)).to be_nil
        end
      end
    end

    context 'when working with multiple accounts' do
      let(:other_account) { create(:account, active_chat_limit_enabled: true, active_chat_limit_value: 20) }
      let(:other_agent) { create(:user, account: other_account) }
      let(:other_service) { described_class.new(account: other_account) }

      before do
        account_user.update!(active_chat_limit_enabled: true, active_chat_limit: 5)
        account.update!(active_chat_limit_enabled: true, active_chat_limit_value: 10)
      end

      it 'returns correct limit for agent in first account' do
        expect(service.limit_for(agent.id)).to eq(5)
      end

      it 'returns correct limit for agent in second account' do
        expect(other_service.limit_for(other_agent.id)).to eq(20)
      end

      it 'returns account limit when querying agent from different account' do
        expect(service.limit_for(other_agent.id)).to eq(10)
      end
    end
  end
end
