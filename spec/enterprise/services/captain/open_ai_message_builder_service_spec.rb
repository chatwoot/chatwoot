require 'rails_helper'

RSpec.describe Captain::OpenAiMessageBuilderService do
  subject(:service) { described_class.new(message: message) }

  let(:message) { create(:message, content: 'Hello world') }

  describe '#generate_content' do
    context 'when message has only text content' do
      it 'returns the text content directly' do
        expect(service.generate_content).to eq('Hello world')
      end
    end

    context 'when message has no content and no attachments' do
      let(:message) { create(:message, content: nil) }

      it 'returns default message' do
        expect(service.generate_content).to eq('Message without content')
      end
    end

    context 'when message has blank content and no attachments' do
      let(:message) { create(:message, content: '') }

      it 'returns default message' do
        expect(service.generate_content).to eq('Message without content')
      end
    end

    context 'when message has text content and image attachments' do
      before do
        attachment = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://example.com/image.jpg')
        attachment.save!
      end

      it 'returns an array with text and image parts' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'text', text: 'Hello world' })
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } })
      end
    end

    context 'when message has only image attachments with external URLs' do
      let(:message) { create(:message, content: nil) }

      before do
        attachment = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://example.com/image.jpg')
        attachment.save!
      end

      it 'returns an array with only image parts' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } })
        expect(result).not_to include(hash_including(type: 'text', text: 'Hello world'))
      end
    end

    context 'when message has multiple image attachments' do
      let(:message) { create(:message, content: nil) }

      before do
        attachment1 = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://example.com/image1.jpg')
        attachment1.save!
        attachment2 = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://example.com/image2.jpg')
        attachment2.save!
      end

      it 'returns an array with all image parts' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://example.com/image1.jpg' } })
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://example.com/image2.jpg' } })
      end
    end

    context 'when message has image attachments with file URLs' do
      let(:message) { create(:message, content: nil) }

      before do
        # Create attachment with external_url to simulate file_url scenario
        attachment = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://local.com/file.jpg')
        attachment.save!
      end

      it 'returns an array with image parts using file URL' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://local.com/file.jpg' } })
      end
    end

    context 'when message has image attachments without valid URLs' do
      let(:message) { create(:message, content: nil) }

      before do
        attachment = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: nil)
        attachment.save!
        allow(attachment).to receive(:file).and_return(instance_double(ActiveStorage::Attached::One, attached?: false))
      end

      it 'returns default message when no valid attachments' do
        result = service.generate_content
        expect(result).to eq('Message without content')
      end
    end

    context 'when message has audio attachments with successful transcription' do
      let(:message) { create(:message, content: nil) }

      before do
        audio_attachment = message.attachments.build(account_id: message.account_id, file_type: :audio)
        audio_attachment.save!
        allow(Messages::AudioTranscriptionService).to receive(:new).with(audio_attachment).and_return(
          instance_double(Messages::AudioTranscriptionService, perform: { success: true, transcriptions: 'Audio transcription text' })
        )
      end

      it 'returns transcription text directly when only one text part' do
        result = service.generate_content
        expect(result).to eq('Audio transcription text')
      end
    end

    context 'when message has multiple audio attachments' do
      let(:message) { create(:message, content: nil) }

      before do
        audio1 = message.attachments.build(account_id: message.account_id, file_type: :audio)
        audio1.save!
        audio2 = message.attachments.build(account_id: message.account_id, file_type: :audio)
        audio2.save!

        allow(Messages::AudioTranscriptionService).to receive(:new).with(audio1).and_return(
          instance_double(Messages::AudioTranscriptionService, perform: { success: true, transcriptions: 'First audio text. ' })
        )
        allow(Messages::AudioTranscriptionService).to receive(:new).with(audio2).and_return(
          instance_double(Messages::AudioTranscriptionService, perform: { success: true, transcriptions: 'Second audio text.' })
        )
      end

      it 'returns concatenated transcription text directly when only one text part' do
        result = service.generate_content
        expect(result).to eq('First audio text. Second audio text.')
      end
    end

    context 'when message has audio attachments with failed transcription' do
      let(:message) { create(:message, content: nil) }

      before do
        audio_attachment = message.attachments.build(account_id: message.account_id, file_type: :audio)
        audio_attachment.save!
        allow(Messages::AudioTranscriptionService).to receive(:new).with(audio_attachment).and_return(
          instance_double(Messages::AudioTranscriptionService, perform: { success: false, transcriptions: nil })
        )
      end

      it 'returns default message when transcription fails' do
        result = service.generate_content
        expect(result).to eq('Message without content')
      end
    end

    context 'when message has text content and audio attachments' do
      before do
        audio_attachment = message.attachments.build(account_id: message.account_id, file_type: :audio)
        audio_attachment.save!
        allow(Messages::AudioTranscriptionService).to receive(:new).with(audio_attachment).and_return(
          instance_double(Messages::AudioTranscriptionService, perform: { success: true, transcriptions: 'Audio text' })
        )
      end

      it 'returns an array with both text content and audio transcription' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'text', text: 'Hello world' })
        expect(result).to include({ type: 'text', text: 'Audio text' })
      end
    end

    context 'when message has non-image/non-audio file attachments' do
      let(:message) { create(:message, content: nil) }

      before do
        attachment = message.attachments.build(account_id: message.account_id, file_type: :file)
        attachment.save!
      end

      it 'returns generic attachment message directly when only one text part' do
        result = service.generate_content
        expect(result).to eq('User has shared an attachment')
      end
    end

    context 'when message has text content and non-image/non-audio file attachments' do
      before do
        attachment = message.attachments.build(account_id: message.account_id, file_type: :file)
        attachment.save!
      end

      it 'returns an array with text content and generic attachment message' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'text', text: 'Hello world' })
        expect(result).to include({ type: 'text', text: 'User has shared an attachment' })
      end
    end

    context 'when message has mixed attachment types' do
      let(:message) { create(:message, content: 'Mixed content') }

      before do
        # Image attachment
        image_attachment = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://example.com/image.jpg')
        image_attachment.save!

        # Audio attachment
        audio_attachment = message.attachments.build(account_id: message.account_id, file_type: :audio)
        audio_attachment.save!
        allow(Messages::AudioTranscriptionService).to receive(:new).with(audio_attachment).and_return(
          instance_double(Messages::AudioTranscriptionService, perform: { success: true, transcriptions: 'Audio text' })
        )

        # File attachment
        file_attachment = message.attachments.build(account_id: message.account_id, file_type: :file)
        file_attachment.save!
      end

      it 'returns an array with all relevant parts' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'text', text: 'Mixed content' })
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } })
        expect(result).to include({ type: 'text', text: 'Audio text' })
        expect(result).to include({ type: 'text', text: 'User has shared an attachment' })
      end
    end

    context 'when message has mixed attachment types without text content' do
      let(:message) { create(:message, content: nil) }

      before do
        # Image attachment
        image_attachment = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://example.com/image.jpg')
        image_attachment.save!

        # Audio attachment
        audio_attachment = message.attachments.build(account_id: message.account_id, file_type: :audio)
        audio_attachment.save!
        allow(Messages::AudioTranscriptionService).to receive(:new).with(audio_attachment).and_return(
          instance_double(Messages::AudioTranscriptionService, perform: { success: true, transcriptions: 'Audio text' })
        )

        # File attachment
        file_attachment = message.attachments.build(account_id: message.account_id, file_type: :file)
        file_attachment.save!
      end

      it 'returns an array with attachment parts only' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } })
        expect(result).to include({ type: 'text', text: 'Audio text' })
        expect(result).to include({ type: 'text', text: 'User has shared an attachment' })
        expect(result).not_to include(hash_including(type: 'text', text: 'Mixed content'))
      end
    end

    context 'when message has some image attachments with URLs and some without' do
      let(:message) { create(:message, content: nil) }

      before do
        # Valid image with external URL
        valid_image = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: 'https://example.com/image.jpg')
        valid_image.save!

        # Invalid image without URL
        invalid_image = message.attachments.build(account_id: message.account_id, file_type: :image, external_url: nil)
        invalid_image.save!
        allow(invalid_image).to receive(:file).and_return(instance_double(ActiveStorage::Attached::One, attached?: false))
      end

      it 'returns an array with only valid image parts' do
        result = service.generate_content
        expect(result).to be_an(Array)
        expect(result).to include({ type: 'image_url', image_url: { url: 'https://example.com/image.jpg' } })
        expect(result.size).to eq(1)
      end
    end
  end
end
