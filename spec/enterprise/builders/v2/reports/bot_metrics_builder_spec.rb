require 'rails_helper'

RSpec.describe V2::Reports::BotMetricsBuilder do
  subject(:bot_metrics_builder) { described_class.new(inbox.account, params) }

  let(:inbox) { create(:inbox) }
  let(:params) { { since: 1.week.ago.to_i.to_s, until: Time.now.to_i.to_s } }
  let(:agent_bot) { create(:agent_bot, account: inbox.account) }
  let(:assistant) { create(:captain_assistant, account: inbox.account) }
  let(:conversation) { create(:conversation, account: inbox.account, inbox: inbox, created_at: 2.days.ago) }

  before do
    create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
  end

  describe '#metrics' do
    it 'counts public messages sent by a Captain assistant' do
      create(:message, account: inbox.account, conversation: conversation, created_at: 2.days.ago, message_type: 'outgoing', sender: assistant)

      expect(bot_metrics_builder.metrics[:message_count]).to eq(1)
    end
  end
end
