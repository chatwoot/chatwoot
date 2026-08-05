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
    it 'locks the account while checking and creating the agent' do
      expect(account).to receive(:with_lock).and_call_original

      agent_builder.perform
    end

    context 'when user does not exist' do
      before { clear_enqueued_jobs }

      it 'creates a new user' do
        expect { agent_builder.perform }.to change(User, :count).by(1)
      end

      it 'creates a new account user' do
        expect { agent_builder.perform }.to change(AccountUser, :count).by(1)
      end

      it 'returns a user' do
        expect(agent_builder.perform).to be_a(User)
      end

      it 'reserves email capacity and enqueues the invitation' do
        allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)

        expect { agent_builder.perform }.to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)
        expect(account.emails_sent_today).to eq(1)
      end

      context 'when the account email limit is exhausted' do
        before do
          allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(true)
          account.update!(limits: { 'emails' => 0 })
        end

        it 'does not create the user or enqueue an invitation' do
          expect { agent_builder.perform }.to raise_error(CustomExceptions::Account::EmailLimitExceeded)
          expect(User.from_email(email)).to be_nil
          expect(AccountUser.find_by(account: account, user: User.from_email(email))).to be_nil
          mail_jobs = enqueued_jobs.select { |job| job[:job].to_s == 'ActionMailer::MailDeliveryJob' }
          expect(mail_jobs).to be_empty
        end
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

      it 'does not consume email capacity or enqueue another invitation' do
        clear_enqueued_jobs

        expect { agent_builder.perform }.not_to have_enqueued_mail(Devise::Mailer, :confirmation_instructions)
        expect(account.emails_sent_today).to eq(0)
      end
    end

    context 'when only email is provided' do
      let(:params) { { email: email, inviter: current_user, account: account } }

      it 'creates a user with default values' do
        user = agent_builder.perform
        expect(user.name).to eq(email.split('@').first)
        expect(AccountUser.find_by(user: user).role).to eq('agent')
      end
    end

    context 'when a temporary password is generated' do
      it 'sets a temporary password for the user' do
        user = agent_builder.perform
        expect(user.encrypted_password).not_to be_empty
      end
    end

    context 'when the account has reached its agent limit' do
      before do
        allow(account).to receive(:usage_limits).and_return({ agents: account.account_users.count })
      end

      it 'raises a limit exceeded error without creating a user' do
        expect { agent_builder.perform }.to raise_error(described_class::LimitExceededError, described_class::LIMIT_EXCEEDED_MESSAGE)

        expect(User.from_email(email)).to be_nil
      end
    end
  end
end
