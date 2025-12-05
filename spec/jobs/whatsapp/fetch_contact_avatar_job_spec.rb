require 'rails_helper'

RSpec.describe Whatsapp::FetchContactAvatarJob, type: :job do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_web', validate_provider_config: false, sync_templates: false) }
  let(:inbox) { whatsapp_channel.inbox }
  let(:identifier) { '5511999887766@s.whatsapp.net' }
  # Create contact with old updated_at to avoid "recently updated" skip logic
  let(:contact) { create(:contact, account: whatsapp_channel.account, updated_at: 25.hours.ago) }

  describe '#perform' do
    context 'when contact and inbox exist and avatar URL is available' do
      it 'enqueues avatar download job' do
        avatar_url = 'https://example.com/avatar.jpg'

        allow_any_instance_of(Channel::Whatsapp).to receive(:avatar_url).with(identifier).and_return(avatar_url)

        expect(Avatar::AvatarFromUrlJob).to receive(:perform_later).with(contact, avatar_url)

        described_class.perform_now(contact.id, inbox.id, identifier)
      end

      it 'does not enqueue download job if avatar URL is blank' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:avatar_url).with(identifier).and_return(nil)

        expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later)

        described_class.perform_now(contact.id, inbox.id, identifier)
      end
    end

    context 'when contact has recent avatar' do
      it 'skips avatar fetch' do
        contact.update!(updated_at: 12.hours.ago)

        # Attach a recent avatar
        contact.avatar.attach(
          io: StringIO.new('fake image'),
          filename: 'avatar.jpg',
          content_type: 'image/jpeg'
        )

        expect_any_instance_of(Channel::Whatsapp).not_to receive(:avatar_url)
        expect(Avatar::AvatarFromUrlJob).not_to receive(:perform_later)

        described_class.perform_now(contact.id, inbox.id, identifier)
      end
    end

    context 'when contact does not exist' do
      it 'returns early without error' do
        expect do
          described_class.perform_now(99_999, inbox.id, identifier)
        end.not_to raise_error
      end
    end

    context 'when inbox does not exist' do
      it 'returns early without error' do
        expect do
          described_class.perform_now(contact.id, 99_999, identifier)
        end.not_to raise_error
      end
    end

    context 'when avatar fetch fails' do
      it 'logs error for connection failures' do
        allow_any_instance_of(Channel::Whatsapp).to receive(:avatar_url).and_raise(Errno::ECONNREFUSED.new('Connection refused'))
        allow(Rails.logger).to receive(:error)

        # The job has retry_on configuration for ECONNREFUSED which handles retries in production
        # Here we just verify that errors are logged properly
        begin
          described_class.perform_now(contact.id, inbox.id, identifier)
        rescue Errno::ECONNREFUSED
          # Expected - error is re-raised after logging
        end

        # Verify error was logged
        expect(Rails.logger).to have_received(:error).with(/Avatar fetch job failed/)
      end
    end
  end
end
