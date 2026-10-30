require 'rails_helper'

RSpec.describe ConversationMonitors::Monitor do
  describe 'slack_channel_id' do
    let(:account) { create(:account) }
    let(:monitor) { create(:conversation_monitor, account: account) }

    it 'requires a connected Slack integration' do
      monitor.update(slack_channel_id: 'C0ALERTS')

      expect(monitor.errors[:slack_channel_id]).to include('needs a connected Slack integration')
    end

    context 'when Slack is connected' do
      before { create(:integrations_hook, account: account) }

      it 'accepts a Slack channel id' do
        expect(monitor.update(slack_channel_id: 'C0ALERTS')).to be(true)
      end

      it 'rejects a malformed channel id' do
        monitor.update(slack_channel_id: '#general')

        expect(monitor.errors[:slack_channel_id]).to include('is invalid')
      end

      it 'stores a blank channel as nil' do
        monitor.update!(slack_channel_id: 'C0ALERTS')
        monitor.update!(slack_channel_id: '')

        expect(monitor.reload.slack_channel_id).to be_nil
      end
    end
  end
end
