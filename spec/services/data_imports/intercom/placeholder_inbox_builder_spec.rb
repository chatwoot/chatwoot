require 'rails_helper'

RSpec.describe DataImports::Intercom::PlaceholderInboxBuilder do
  let(:account) { create(:account) }

  describe '#inbox_for' do
    it 'creates a source-bucket API inbox for an Intercom conversation source' do
      inbox = described_class.new(account: account).inbox_for('email')

      expect(inbox.name).to eq('Intercom Import - Email')
      expect(inbox.channel).to be_a(Channel::Api)
      expect(inbox.enable_auto_assignment).to be(false)
      expect(inbox.allow_messages_after_resolved).to be(false)
      expect(inbox.channel.additional_attributes).to include(
        'source_provider' => 'intercom',
        'source_bucket' => 'email',
        'import_placeholder' => true,
        'agent_reply_time_window' => 1
      )
    end

    it 'reuses an existing placeholder inbox for the same source bucket' do
      builder = described_class.new(account: account)

      first_inbox = builder.inbox_for('phone_call')
      expect(account).not_to receive(:inboxes)
      second_inbox = builder.inbox_for('phone_switch')

      expect(second_inbox).to eq(first_inbox)
      expect(Inbox.where(account: account, channel_type: 'Channel::Api').count).to eq(1)
    end
  end
end
