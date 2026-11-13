require 'rails_helper'

RSpec.describe Integrations::Hook do
  let(:account) { create(:account) }
  let(:other_account) { create(:account) }
  let!(:slack_hook) { create(:integrations_hook, account: account) }
  let(:monitor) { create(:conversation_monitor, account: account, slack_channel_id: 'C0ALERTS') }
  let(:other_account_monitor) { create(:conversation_monitor, account: other_account, slack_channel_id: 'C0OTHER') }

  before do
    create(:integrations_hook, account: other_account)
    monitor
    other_account_monitor
  end

  it 'clears monitor Slack channels when the Slack integration is disconnected' do
    slack_hook.destroy!

    expect(monitor.reload.slack_channel_id).to be_nil
    expect(other_account_monitor.reload.slack_channel_id).to eq('C0OTHER')
  end

  it 'keeps monitor Slack channels when another integration is removed' do
    create(:integrations_hook, :google_translate, account: account).destroy!

    expect(monitor.reload.slack_channel_id).to eq('C0ALERTS')
  end
end
