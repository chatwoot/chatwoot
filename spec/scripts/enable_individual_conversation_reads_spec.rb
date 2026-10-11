require 'rails_helper'

RSpec.describe 'Individual read state activation' do # rubocop:disable RSpec/DescribeClass
  let(:account) { create(:account) }
  let(:reader) { create(:user, account: account, role: :administrator) }
  let(:conversation) { create(:conversation, account: account, agent_last_seen_at: 10.minutes.ago) }
  let(:script) { Rails.root.join('script/enable_individual_conversation_reads.rb') }

  it 'preserves the old marker and never resets personal receipts on a repeated activation' do
    conversation
    with_modified_env(ACCOUNT_ID: account.id.to_s, APPLY: 'true') do
      expect { load script }.to output(/"applied":true/).to_stdout
      expect(account.reload.feature_enabled?(:individual_conversation_reads)).to be(true)
      expect(conversation.reload.read_baseline_at).to eq(conversation.agent_last_seen_at)

      create(:message, account: account, conversation: conversation, message_type: :incoming, created_at: 1.minute.ago)
      Conversations::ReadStateService.new(conversation: conversation, user: reader).mark_read
      baseline = conversation.reload.read_baseline_at
      expect { load script }.to output(/"applied":true/).to_stdout
      expect(conversation.reload.read_baseline_at).to eq(baseline)
      expect(conversation.conversation_read_states.where(user: reader).count).to eq(1)
    end
  end
end
