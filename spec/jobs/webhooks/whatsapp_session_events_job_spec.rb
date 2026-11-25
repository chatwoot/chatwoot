require 'rails_helper'

RSpec.describe Webhooks::WhatsappSessionEventsJob do
  subject(:job) { described_class }

  # Pointed at the instance the captured bodies name, since the translator refuses one
  # that says it came from somewhere else.
  let(:channel) do
    create(:channel_whatsapp, provider: 'uazapi', sync_templates: false, validate_provider_config: false,
                              provider_config: { 'base_url' => 'https://free.uazapi.com', 'token' => 'instance-token' })
  end
  let(:dispatcher) { Whatsapp::Session::Inbound::Dispatcher }
  let(:body) { JSON.parse(Rails.root.join('spec/fixtures/whatsapp/session/uazapi/webhook/message_incoming_text.json').read) }

  it 'dispatches what the body translates to' do
    allow(dispatcher).to receive(:dispatch).and_return(:handled)

    job.perform_now(channel, body)

    expect(dispatcher).to have_received(:dispatch).with(channel, having_attributes(type: 'message.received'), instance: nil)
  end

  # A body this build cannot read produces nothing, which is what lets the provider send
  # an event type Chatwoot has never heard of without the inbox failing on every delivery.
  it 'does nothing with an event type it does not translate' do
    allow(dispatcher).to receive(:dispatch)

    job.perform_now(channel, { 'EventType' => 'labels' })

    expect(dispatcher).not_to have_received(:dispatch)
  end

  # Re-pointed while the body sat in the queue. The token that authenticated it is gone by
  # then and two instances of a hosted provider share a base URL, so the fingerprint taken
  # when it arrived is the only thing left that says which instance it was meant for.
  it 'writes nothing from a body the inbox has since stopped listening to' do
    fingerprint = Whatsapp::Session::Registry.instance_fingerprint(channel)
    # The move itself lets go of the instance being left, which is a request of its own.
    stub_request(:post, 'https://free.uazapi.com/webhook').to_return(status: 200, body: '{}')
    channel.update!(provider_config: channel.provider_config.merge('token' => 'another-instance'))

    job.perform_now(channel.reload, body, fingerprint)

    expect(channel.inbox.messages).to be_empty
  end

  # Converted while the body sat in the queue: this provider's events are not this
  # inbox's business any more, and there is no translator to read them with.
  it 'does nothing for an inbox that has left the session layer' do
    allow(dispatcher).to receive(:dispatch)
    channel.update_column(:provider, 'whatsapp_cloud') # rubocop:disable Rails/SkipsModelValidations

    job.perform_now(channel, body)

    expect(dispatcher).not_to have_received(:dispatch)
  end

  # The webhook has no ordering guarantee and the payloads carry nothing to rebuild one
  # from, so a handler that cannot find the message its event is about asks to be run
  # again rather than dropping the edit, the revoke or the reaction for good.
  describe 'when the event arrived before the message it refers to' do
    before { allow(dispatcher).to receive(:dispatch).and_return(:deferred) }

    it 'comes back later instead of dropping it' do
      expect { job.perform_now(channel, body) }.to have_enqueued_job(described_class)
    end

    # A history slice waiting for an import slot can hold the message for longer than the
    # ladder lasts, so while one is queued the wait does not spend it.
    it 'waits out a history import still queued for the inbox, a minute at a time' do
      Whatsapp::Session::HistoryImportJob.queued(channel.inbox, 'slice-1')

      freeze_time do
        expect { job.perform_now(channel, body) }.to have_enqueued_job(described_class).at(1.minute.from_now)
      end
    ensure
      Redis::Alfred.delete(Whatsapp::Session::HistoryImportJob.pending_key(channel.inbox))
    end
  end

  # A bulk deletion is one event per message id. Stopping at the first one whose message
  # is not stored would leave the rest undispatched, and every retry would stop at the
  # same id: the messages after it would never be deleted at all.
  describe 'when only part of a batch has to wait' do
    let(:deletion) do
      JSON.parse(Rails.root.join('spec/fixtures/whatsapp/session/uazapi/webhook/update_deleted.json').read)
          .tap { |raw| raw['event']['MessageIDs'] = %w[3EB0MISSING 3EB0STORED] }
    end

    before do
      allow(dispatcher).to receive(:dispatch) do |_channel, event|
        event.payload.message_id == '3EB0MISSING' ? :deferred : :handled
      end
    end

    it 'dispatches every event before asking to come back' do
      expect { job.perform_now(channel, deletion) }.to have_enqueued_job(described_class)

      expect(dispatcher).to have_received(:dispatch).twice
    end
  end

  # A shape this build cannot parse is a provider or contract problem, and running it
  # again produces the same nothing.
  it 'drops a payload it cannot read rather than retrying it' do
    allow(dispatcher).to receive(:dispatch).and_raise(Whatsapp::Session::Errors::InvalidPayload, 'bad shape')

    expect { job.perform_now(channel, body) }.not_to have_enqueued_job(described_class)
  end
end
