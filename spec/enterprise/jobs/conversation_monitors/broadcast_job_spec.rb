require 'rails_helper'

RSpec.describe ConversationMonitors::BroadcastJob do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account) }

  %w[reports conversation_monitors enterprise].each do |feature|
    it "does not broadcast if #{feature} is disabled after scheduling" do
      account.enable_features!('reports', 'conversation_monitors')
      create(:user, account: account, role: :administrator)
      described_class.schedule(monitor.id)
      if feature == 'enterprise'
        allow(ChatwootApp).to receive(:enterprise?).and_return(false)
      else
        account.disable_features!(feature)
      end

      expect { described_class.perform_now(monitor.id) }.not_to have_enqueued_job(ActionCableBroadcastJob)
    end
  end

  it 'broadcasts pause updates while the feature remains enabled' do
    account.enable_features!('reports', 'conversation_monitors')
    admin = create(:user, account: account, role: :administrator)
    monitor.update!(paused_at: Time.current)

    expect { described_class.perform_now(monitor.id) }.to have_enqueued_job(ActionCableBroadcastJob).with(
      [admin.pubsub_token], 'monitor.updated', { account_id: account.id, monitor_id: monitor.id, data_revision: 0 }
    )
  end

  it 'broadcasts a tombstone after the monitor is soft deleted' do
    account.enable_features!('reports', 'conversation_monitors')
    admin = create(:user, account: account, role: :administrator)
    monitor.update!(deleted_at: Time.current, data_revision: 1)

    expect { described_class.perform_now(monitor.id) }.to have_enqueued_job(ActionCableBroadcastJob).with(
      [admin.pubsub_token], 'monitor.updated',
      { account_id: account.id, monitor_id: monitor.id, data_revision: 1, deleted: true }
    )
  end

  it 'only broadcasts minimal invalidations to currently authorized report viewers' do
    account.enable_features!('reports', 'conversation_monitors')
    admin = create(:user, account: account, role: :administrator)
    viewer = create(:user, account: account, role: :agent)
    create(:user, account: account, role: :agent)
    role = create(:custom_role, account: account, permissions: ['report_manage'])
    account.account_users.find_by!(user: viewer).update!(custom_role: role)

    expect do
      described_class.perform_now(monitor.id)
    end.to have_enqueued_job(ActionCableBroadcastJob).with(
      contain_exactly(admin.pubsub_token, viewer.pubsub_token), 'monitor.updated',
      { account_id: account.id, monitor_id: monitor.id, data_revision: 0 }
    )
  end

  it 'allows a later result to schedule an update as soon as the previous broadcast starts' do
    account.enable_features!('reports', 'conversation_monitors')
    admin = create(:user, account: account, role: :administrator)
    described_class.schedule(monitor.id)
    described_class.perform_now(monitor.id)
    monitor.update!(data_revision: 1)

    expect { described_class.schedule(monitor.id) }.to have_enqueued_job(described_class).with(monitor.id)
    expect do
      described_class.perform_now(monitor.id)
    end.to have_enqueued_job(ActionCableBroadcastJob).with(
      [admin.pubsub_token], 'monitor.updated', { account_id: account.id, monitor_id: monitor.id, data_revision: 1 }
    )
  end
end
