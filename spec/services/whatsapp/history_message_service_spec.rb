require 'rails_helper'

describe Whatsapp::HistoryMessageService do
  let(:channel) do
    create(:channel_whatsapp,
           phone_number: '+15550783881',
           provider: 'whatsapp_cloud',
           provider_config: { 'api_key' => 'test_token', 'phone_number_id' => 'PN_123', 'source' => 'embedded_signup' },
           sync_templates: false,
           validate_provider_config: false)
  end
  let(:inbox) { channel.inbox }

  # Realistic Coexistence `history` payload: one phase-0 chunk, one 1:1 thread with an inbound
  # text, an outbound text, and an outbound media message (placeholder — no downloadable id).
  let(:params) do
    {
      object: 'whatsapp_business_account',
      entry: [{
        id: 'WABA_ID',
        changes: [{
          field: 'history',
          value: {
            messaging_product: 'whatsapp',
            metadata: { display_phone_number: '15550783881', phone_number_id: 'PN_123' },
            history: [{
              metadata: { phase: 0, chunk_order: 1, progress: 100 },
              threads: [{
                id: '16505551234',
                messages: [
                  { from: '16505551234', to: '15550783881', id: 'wamid.in1', timestamp: '1739230955',
                    type: 'text', text: { body: 'Oi, boa tarde' }, history_context: { status: 'READ' } },
                  { from: '15550783881', to: '16505551234', id: 'wamid.out1', timestamp: '1739230999',
                    type: 'text', text: { body: 'Ola, tudo bem?' } },
                  { from: '15550783881', to: '16505551234', id: 'wamid.media1', timestamp: '1739231050',
                    type: 'image', image: { caption: 'foto antiga', mime_type: 'image/jpeg', sha256: 'abc' } }
                ]
              }]
            }]
          }
        }]
      }]
    }.with_indifferent_access
  end

  def perform!
    with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
      described_class.new(inbox: inbox, params: params).perform
    end
  end

  describe '#perform' do
    it 'imports the full thread as one conversation with correctly-directed, historically-timestamped messages' do
      # Reason: history backfill must recreate past 1:1 chats with real timestamps and directions.
      expect { perform! }.to change(Conversation, :count).by(1)

      conversation = Conversation.last
      expect(conversation.messages.count).to eq(3)

      inbound = Message.find_by(source_id: 'wamid.in1')
      outbound = Message.find_by(source_id: 'wamid.out1')
      expect(inbound).to be_incoming
      expect(inbound.content).to eq('Oi, boa tarde')
      expect(inbound.created_at.to_i).to eq(1_739_230_955)
      expect(outbound).to be_outgoing
      expect(outbound.created_at.to_i).to eq(1_739_230_999)
    end

    it 'creates the contact from the thread id' do
      # Reason: the thread id is the WhatsApp user phone; the imported chat must attach to a contact.
      perform!
      contact = Contact.find_by(phone_number: '+16505551234')
      expect(contact).to be_present
    end

    it 'persists media history as a placeholder (no downloadable id in the history payload)' do
      # Reason: history media carries no asset id inline, so we store a placeholder, not an attachment.
      perform!
      media = Message.find_by(source_id: 'wamid.media1')
      expect(media).to be_outgoing
      expect(media.content).to eq('foto antiga')
      expect(media.attachments).to be_empty
      expect(media.content_attributes['is_history_media_placeholder']).to be(true)
    end

    it 'does not trigger new-message side effects (no SendReplyJob for imported messages)' do
      # Reason: historical outgoing messages must NOT be re-sent, and no notifications/automation fire.
      expect { perform! }.not_to have_enqueued_job(SendReplyJob)
    end

    it 'is idempotent — re-delivering the same chunk does not duplicate messages' do
      # Reason: Meta retries on non-2xx and chunks can repeat; dedupe by source_id must hold.
      perform!
      expect { perform! }.not_to change(Message, :count)
    end

    it 'does nothing when the flag is off' do
      # Reason: the handler is gated; an unexpected history webhook with the flag off is ignored.
      expect do
        described_class.new(inbox: inbox, params: params).perform
      end.not_to change(Message, :count)
    end

    it 'does not raise on a malformed payload' do
      # Reason: a 500 would make Meta retry the whole chunk; malformed input must be swallowed.
      broken = { entry: [{ changes: [{ field: 'history', value: { history: 'not-an-array' } }] }] }.with_indifferent_access
      with_modified_env WHATSAPP_HISTORY_SYNC_ENABLED: 'true' do
        expect { described_class.new(inbox: inbox, params: broken).perform }.not_to raise_error
      end
    end

    it 'does not dispatch CONVERSATION_CREATED for the imported conversation' do
      # Reason: an imported conversation must not flood automation/notifications/webhooks/CRM.
      allow(Rails.configuration.dispatcher).to receive(:dispatch).and_call_original
      perform!
      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(Conversation::CONVERSATION_CREATED, anything, anything)
    end

    # Serialization against a concurrent redelivery of the same chunk now lives at the caller
    # (Webhooks::WhatsappEventsJob#handle_history_event, via the per-inbox WHATSAPP_HISTORY_SYNC_MUTEX
    # lock) so a conflict raises and is retried by ActiveJob instead of this service silently
    # skipping the chunk after the webhook already returned 200. See
    # spec/jobs/webhooks/whatsapp_events_job_spec.rb for that coverage.
  end
end
