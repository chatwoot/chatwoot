require 'rails_helper'

RSpec.describe Whatsapp::Session::Inbound::EchoMatcher do
  let(:channel) { create(:channel_whatsapp, provider: 'native', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, inbox: inbox, account: channel.account) }
  let(:message) do
    create(:message, conversation: conversation, inbox: inbox, account: channel.account,
                     message_type: :outgoing, content: 'olá!')
  end

  before { message.update_under_lock!(pending_source_id: '3EB0RESERVED') }

  it 'finds the send its reservation belongs to and fills in the provider id' do
    found = described_class.new(inbox: inbox, message_id: '3EB0FROMPROVIDER', client_ref: '3EB0RESERVED').perform

    expect(found).to eq(message)
    expect(message.reload.source_id).to eq('3EB0FROMPROVIDER')
  end

  it 'ignores an echo of a message this inbox never sent' do
    expect(described_class.new(inbox: inbox, message_id: 'UNKNOWN', client_ref: 'UNKNOWN').perform).to be_nil
  end

  it 'revokes a message the agent deleted while the send was in flight' do
    message.update_under_lock!(deleted: true)

    expect { described_class.new(inbox: inbox, message_id: '3EB0FROMPROVIDER', client_ref: '3EB0RESERVED').perform }
      .to have_enqueued_job(Messages::DeleteOnChannelJob).once
  end

  # Enqueued inside the row lock, the job can be picked up before the transaction commits:
  # it reads a still-blank source_id, returns, and the send response then sees the id
  # already set and enqueues nothing. The deleted message stays on WhatsApp.
  it 'enqueues the revoke only after the assignment has committed' do
    message.update_under_lock!(deleted: true)
    depth_outside = ActiveRecord::Base.connection.open_transactions
    depth_at_enqueue = nil
    allow(Messages::DeleteOnChannelJob).to receive(:perform_later) do
      depth_at_enqueue = ActiveRecord::Base.connection.open_transactions
    end

    described_class.new(inbox: inbox, message_id: '3EB0FROMPROVIDER', client_ref: '3EB0RESERVED').perform

    expect(depth_at_enqueue).to eq(depth_outside)
  end
end
