require 'rails_helper'

RSpec.describe MessagePolicy, type: :policy do
  subject { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:agent_bot) { create(:agent_bot) }
  let(:administrator_context) { { user: administrator, account: account, account_user: administrator.account_users.find_by(account: account) } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.find_by(account: account) } }
  let(:agent_bot_context) { { user: agent_bot, account: account, account_user: nil } }

  let(:message) { create(:message, account: account) }

  permissions :destroy? do
    context 'when the account does not block agent message deletion' do
      it 'allows an agent to delete' do
        expect(subject).to permit(agent_context, message)
      end
    end

    context 'when the account blocks agent message deletion' do
      before { account.update!(disable_agent_message_deletion: true) }

      it 'denies an agent' do
        expect(subject).not_to permit(agent_context, message)
      end

      it 'allows an administrator' do
        expect(subject).to permit(administrator_context, message)
      end

      it 'allows an agent bot' do
        expect(subject).to permit(agent_bot_context, message)
      end

      # The id outlives the role it named when Enterprise is not loaded, or the role was deleted.
      it 'denies an agent whose custom role id names no role in force' do
        agent_context[:account_user].update_column(:custom_role_id, 999_999) # rubocop:disable Rails/SkipsModelValidations

        expect(subject).not_to permit(agent_context, message)
      end
    end
  end
end
