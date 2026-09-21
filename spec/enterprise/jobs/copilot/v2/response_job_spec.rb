require 'rails_helper'

RSpec.describe Copilot::V2::ResponseJob do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:thread) { create(:captain_copilot_thread, account: account, user: user, engine: :v2, assistant: nil) }

  let(:message) { create(:captain_copilot_message, copilot_thread: thread) }

  before { account.enable_features!('copilot_v2') }

  it 'creates the isolated durable run without calling Captain' do
    expect(Copilot::V2::RunJob).to receive(:perform_later).with(kind_of(Integer))
    expect(Captain::Copilot::ChatService).not_to receive(:new)
    described_class.perform_now(account_id: account.id, user_id: user.id, copilot_thread_id: thread.id, copilot_message_id: message.id)
  end

  it 'does not execute new work while the rollout flag is disabled' do
    account.disable_features!('copilot_v2')
    expect(Copilot::V2::ChatService).not_to receive(:new)
    expect do
      described_class.perform_now(account_id: account.id, user_id: user.id, copilot_thread_id: thread.id, copilot_message_id: message.id)
    end.to raise_error(Copilot::V2::RunService::Unavailable)
  end

  it 'rejects threads belonging to another user' do
    other_user = create(:user, account: account)
    expect do
      described_class.perform_now(account_id: account.id, user_id: other_user.id, copilot_thread_id: thread.id, copilot_message_id: message.id)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'rejects threads belonging to another account' do
    other_account = create(:account)
    expect do
      described_class.perform_now(account_id: other_account.id, user_id: user.id, copilot_thread_id: thread.id, copilot_message_id: message.id)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'does not run legacy threads through v2' do
    legacy_thread = create(:captain_copilot_thread, account: account, user: user)
    expect do
      described_class.perform_now(account_id: account.id, user_id: user.id, copilot_thread_id: legacy_thread.id, copilot_message_id: message.id)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
