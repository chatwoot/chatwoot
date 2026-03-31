require 'rails_helper'

RSpec.describe RetryWhatsappTemplateMessagesJob do
  subject(:job) { described_class.new }

  let!(:whatsapp_channel) { create(:channel_whatsapp, sync_templates: false, validate_provider_config: false) }
  let!(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, source_id: '123456789') }
  let!(:conversation) { create(:conversation, contact_inbox: contact_inbox, inbox: whatsapp_channel.inbox) }

  let(:template_params) do
    {
      'name' => 'sample_shipping_confirmation',
      'namespace' => '23423423_2342423_324234234_2343224',
      'language' => 'en_US',
      'category' => 'Marketing',
      'processed_params' => { 'body' => { '1' => '3' } }
    }
  end

  def create_failed_template_message(attrs = {})
    create(:message,
           message_type: :outgoing,
           status: :failed,
           conversation: conversation,
           additional_attributes: { 'template_params' => template_params },
           content_attributes: attrs.fetch(:content_attributes, {}),
           created_at: attrs.fetch(:created_at, 2.days.ago))
  end

  before do
    allow_any_instance_of(Whatsapp::SendOnWhatsappService).to receive(:perform_reply)
  end

  describe '#perform' do
    context 'when message is eligible and delay has elapsed' do
      it 'retries and marks message as sent on success' do
        message = create_failed_template_message(created_at: 2.days.ago)

        job.perform

        message.reload
        expect(message.status).to eq('sent')
        expect(message.content_attributes['retry_count']).to be_nil
        expect(message.content_attributes['last_failed_at']).to be_nil
      end
    end

    context 'when retry delay has not elapsed' do
      it 'does not retry the message' do
        message = create_failed_template_message(created_at: 12.hours.ago)

        job.perform

        message.reload
        expect(message.status).to eq('failed')
      end
    end

    context 'when retry_count has reached MAX_RETRIES' do
      it 'does not retry the message' do
        message = create_failed_template_message(
          created_at: 8.days.ago + 1.hour,
          content_attributes: { 'retry_count' => 7 }
        )

        job.perform

        message.reload
        expect(message.status).to eq('failed')
      end
    end

    context 'when retry_abandoned is already set' do
      it 'does not retry the message' do
        message = create_failed_template_message(
          content_attributes: { 'retry_abandoned' => 'contact_replied' }
        )

        job.perform

        message.reload
        expect(message.status).to eq('failed')
      end
    end

    context 'when the contact has replied after the template message' do
      it 'abandons with contact_replied reason' do
        message = create_failed_template_message(created_at: 2.days.ago)

        # Create an incoming reply after the template message
        create(:message,
               message_type: :incoming,
               conversation: conversation,
               created_at: message.created_at + 1.hour)

        job.perform

        message.reload
        expect(message.status).to eq('failed')
        expect(message.content_attributes['retry_abandoned']).to eq('contact_replied')
      end
    end

    context 'when the template no longer exists on the channel' do
      it 'abandons with template_not_found reason' do
        message = create_failed_template_message(created_at: 2.days.ago)

        # Remove all templates from the channel
        whatsapp_channel.update!(message_templates: [])

        job.perform

        message.reload
        expect(message.status).to eq('failed')
        expect(message.content_attributes['retry_abandoned']).to eq('template_not_found')
      end
    end

    context 'when the retry attempt fails' do
      before do
        allow_any_instance_of(Whatsapp::SendOnWhatsappService)
          .to receive(:perform_reply).and_raise(StandardError, 'API timeout')
      end

      it 'increments retry_count and sets last_failed_at' do
        message = create_failed_template_message(created_at: 2.days.ago)

        job.perform

        message.reload
        expect(message.status).to eq('failed')
        expect(message.content_attributes['retry_count']).to eq(1)
        expect(message.content_attributes['last_failed_at']).to be_present
      end

      it 'marks retry_abandoned as max_retries on the 7th failure' do
        message = create_failed_template_message(
          created_at: 8.days.ago + 1.hour,
          content_attributes: { 'retry_count' => 6 }
        )

        job.perform

        message.reload
        expect(message.content_attributes['retry_count']).to eq(7)
        expect(message.content_attributes['retry_abandoned']).to eq('max_retries')
      end
    end

    context 'when one message errors but another is eligible' do
      it 'continues processing the second message' do
        call_count = 0
        allow_any_instance_of(Whatsapp::SendOnWhatsappService).to receive(:perform_reply) do
          call_count += 1
          raise StandardError, 'boom' if call_count == 1
        end

        message1 = create_failed_template_message(created_at: 2.days.ago)
        message2 = create_failed_template_message(created_at: 2.days.ago)

        job.perform

        message1.reload
        message2.reload

        # First message failed retry, second succeeded
        expect(message1.content_attributes['retry_count']).to eq(1)
        expect(message2.status).to eq('sent')
      end
    end

    context 'when message is older than 8 days' do
      it 'is not selected for retry' do
        message = create_failed_template_message(created_at: 9.days.ago)

        job.perform

        message.reload
        expect(message.status).to eq('failed')
        expect(message.content_attributes['retry_count']).to be_nil
      end
    end

    context 'when message has no template_params' do
      it 'is not selected for retry' do
        message = create(:message,
                         message_type: :outgoing,
                         status: :failed,
                         conversation: conversation,
                         additional_attributes: {},
                         created_at: 2.days.ago)

        job.perform

        message.reload
        expect(message.status).to eq('failed')
      end
    end

    context 'when message status is sent' do
      it 'is not selected for retry' do
        message = create(:message,
                         message_type: :outgoing,
                         status: :sent,
                         conversation: conversation,
                         additional_attributes: { 'template_params' => template_params },
                         created_at: 2.days.ago)

        job.perform

        message.reload
        expect(message.status).to eq('sent')
        expect(message.content_attributes['retry_count']).to be_nil
      end
    end

    context 'when backoff schedule is respected across multiple retries' do
      it 'does not retry at 36h for a message with retry_count 1' do
        # retry_count=1 means next retry requires (1+1)*24h = 48h from created_at
        message = create_failed_template_message(
          created_at: 36.hours.ago,
          content_attributes: { 'retry_count' => 1, 'last_failed_at' => 25.hours.ago.iso8601 }
        )

        job.perform

        message.reload
        expect(message.content_attributes['retry_count']).to eq(1) # unchanged
      end

      it 'retries at 49h for a message with retry_count 1' do
        message = create_failed_template_message(
          created_at: 49.hours.ago,
          content_attributes: { 'retry_count' => 1, 'last_failed_at' => 25.hours.ago.iso8601 }
        )

        job.perform

        message.reload
        expect(message.status).to eq('sent')
      end
    end

    context 'when manual retry resets content_attributes' do
      it 'message becomes eligible for automatic retry again' do
        # Simulate manual retry: content_attributes cleared, status back to failed
        # (as if the manual retry also failed at the provider level)
        message = create_failed_template_message(
          created_at: 2.days.ago,
          content_attributes: {}
        )

        job.perform

        message.reload
        expect(message.status).to eq('sent')
      end
    end
  end
end
