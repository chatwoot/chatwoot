require 'rails_helper'

RSpec.describe AgentBuilder, type: :model do
  subject(:agent_builder) { described_class.new(params) }

  let(:account) { create(:account) }
  let!(:current_user) { create(:user, account: account) }
  let(:email) { 'test@example.com' }
  let(:name) { 'Test User' }
  let(:role) { 'agent' }
  let(:availability) { 'offline' }
  let(:auto_offline) { false }
  let(:params) do
    {
      email: email,
      name: name,
      inviter: current_user,
      account: account,
      role: role,
      availability: availability,
      auto_offline: auto_offline
    }
  end

  describe '#perform' do
    context 'when user does not exist' do
      it 'creates a new user' do
        expect { agent_builder.perform }.to change(User, :count).by(1)
      end

      it 'creates a new account user' do
        expect { agent_builder.perform }.to change(AccountUser, :count).by(1)
      end

      it 'returns a user' do
        expect(agent_builder.perform).to be_a(User)
      end
    end

    context 'when user exists' do
      before do
        create(:user, email: email)
      end

      it 'does not create a new user' do
        expect { agent_builder.perform }.not_to change(User, :count)
      end

      it 'creates a new account user' do
        expect { agent_builder.perform }.to change(AccountUser, :count).by(1)
      end
    end

    context 'when only email is provided' do
      let(:params) { { email: email, inviter: current_user, account: account } }

      it 'creates a user with default values' do
        user = agent_builder.perform
        expect(user.name).to eq('')
        expect(AccountUser.find_by(user: user).role).to eq('agent')
      end
    end

    context 'when a temporary password is generated' do
      it 'sets a temporary password for the user' do
        user = agent_builder.perform
        expect(user.encrypted_password).not_to be_empty
      end
    end

    context 'with confirmation required' do
      let(:unconfirmed_user) { create(:user, email: email) }

      before do
        unconfirmed_user.confirmed_at = nil
        unconfirmed_user.save(validate: false)
        allow(unconfirmed_user).to receive(:confirmed?).and_return(false)
      end

      it 'sends confirmation instructions' do
        user = agent_builder.perform
        expect(user).to receive(:send_confirmation_instructions)
        agent_builder.send(:send_confirmation_if_required)
      end
    end
  end
end
