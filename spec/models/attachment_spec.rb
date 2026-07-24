require 'rails_helper'

RSpec.describe Attachment do
  let!(:message) { create(:message) }

  describe 'external url validations' do
    let(:attachment) { message.attachments.new(account_id: message.account_id, file_type: :image) }

    before do
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
    end

    context 'when it validates external url length' do
      it 'valid when within limit' do
        attachment.external_url = 'a' * Limits::URL_LENGTH_LIMIT
        expect(attachment.valid?).to be true
      end

      it 'invalid when crossed the limit' do
        attachment.external_url = 'a' * (Limits::URL_LENGTH_LIMIT + 5)
        attachment.valid?
        expect(attachment.errors[:external_url]).to include("is too long (maximum is #{Limits::URL_LENGTH_LIMIT} characters)")
      end
    end
  end

  describe 'download_url' do
    it 'returns valid download url' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      expect(attachment.download_url).not_to be_nil
    end
  end

  describe 'with_attached_file?' do
    it 'returns true if its an attachment with file' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      expect(attachment.with_attached_file?).to be true
    end

    it 'returns false if its an attachment with out a file' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :fallback)
      expect(attachment.with_attached_file?).to be false
    end
  end

  describe 'push_event_data for instagram story mentions' do
    let(:instagram_message) { create(:message, :instagram_story_mention) }

    before do
      # stubbing the request to facebook api during the message creation
      stub_request(:get, %r{https://graph.facebook.com/.*}).to_return(status: 200, body: {
        story: { mention: { link: 'http://graph.facebook.com/test-story-mention', id: '17920786367196703' } },
        from: { username: 'Sender-id-1', id: 'Sender-id-1' },
        id: 'instagram-message-id-1234'
      }.to_json, headers: {})
    end

    it 'returns original attachment url as data url if the message is outgoing' do
      message = create(:message, :instagram_story_mention, message_type: :outgoing)
      expect(message.attachments.first.push_event_data[:data_url]).not_to eq message.attachments.first.external_url
    end
  end

  describe 'thumb_url' do
    it 'returns empty string for non-image attachments' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')

      expect(attachment.thumb_url).to eq('')
    end

    it 'generates thumb_url for image attachments' do
      attachment = message.attachments.create!(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: StringIO.new('fake image'), filename: 'test.jpg', content_type: 'image/jpeg')

      expect(attachment.thumb_url).to be_present
    end

    it 'handles unrepresentable images gracefully' do
      attachment = message.attachments.create!(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: StringIO.new('fake image'), filename: 'test.jpg', content_type: 'image/jpeg')

      allow(attachment.file).to receive(:representation).and_raise(ActiveStorage::UnrepresentableError.new('Cannot represent'))

      expect(Rails.logger).to receive(:warn).with(/Unrepresentable image attachment: #{attachment.id}/)
      expect(attachment.thumb_url).to eq('')
    end
  end

  describe 'meta data handling' do
    let(:message) { create(:message) }

    context 'when attachment is a contact type' do
      let(:contact_attachment) do
        message.attachments.create!(
          account_id: message.account_id,
          file_type: :contact,
          fallback_title: '+1234567890',
          meta: {
            first_name: 'John',
            last_name: 'Doe'
          }
        )
      end

      it 'stores and retrieves meta data correctly' do
        expect(contact_attachment.meta['first_name']).to eq('John')
        expect(contact_attachment.meta['last_name']).to eq('Doe')
      end

      it 'includes meta data in push_event_data' do
        event_data = contact_attachment.push_event_data
        expect(event_data[:meta]).to eq({
                                          'first_name' => 'John',
                                          'last_name' => 'Doe'
                                        })
      end

      it 'returns empty hash for meta if not set' do
        attachment = message.attachments.create!(
          account_id: message.account_id,
          file_type: :contact,
          fallback_title: '+1234567890'
        )
        expect(attachment.push_event_data[:meta]).to eq({})
      end
    end

    context 'when meta is used with other file types' do
      let(:image_attachment) do
        attachment = message.attachments.new(
          account_id: message.account_id,
          file_type: :image,
          meta: { description: 'Test image' }
        )
        attachment.file.attach(
          io: Rails.root.join('spec/assets/avatar.png').open,
          filename: 'avatar.png',
          content_type: 'image/png'
        )
        attachment.save!
        attachment
      end

      it 'preserves meta data with file attachments' do
        expect(image_attachment.meta['description']).to eq('Test image')
      end
    end
  end

  describe 'push_event_data for instagram direct message attachments' do
    let(:account) { create(:account) }
    let(:instagram_inbox) do
      create(:inbox, account: account,
                     channel: create(:channel_instagram_fb_page, account: account, instagram_id: 'instagram-dm-test'))
    end

    context 'when conversation type is instagram_direct_message' do
      let(:conversation) do
        create(:conversation, account: account, inbox: instagram_inbox,
                              additional_attributes: { 'type' => 'instagram_direct_message' })
      end
      let(:instagram_message) { create(:message, account: account, inbox: instagram_inbox, conversation: conversation, message_type: :incoming) }

      it 'uses external_url for data_url and thumb_url' do
        attachment = instagram_message.attachments.new(account_id: account.id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).to eq('https://instagram.com/image.jpg')
        expect(event_data[:thumb_url]).to eq('https://instagram.com/image.jpg')
      end
    end

    context 'when conversation type is not instagram_direct_message' do
      let(:conversation) do
        create(:conversation, account: account, inbox: instagram_inbox,
                              additional_attributes: { 'type' => 'other_type' })
      end
      let(:instagram_message) { create(:message, account: account, inbox: instagram_inbox, conversation: conversation, message_type: :incoming) }

      it 'uses file_url for data_url instead of external_url' do
        attachment = instagram_message.attachments.new(account_id: account.id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).not_to eq('https://instagram.com/image.jpg')
      end
    end

    context 'when message is outgoing on instagram DM conversation' do
      let(:conversation) do
        create(:conversation, account: account, inbox: instagram_inbox,
                              additional_attributes: { 'type' => 'instagram_direct_message' })
      end
      let(:outgoing_message) { create(:message, account: account, inbox: instagram_inbox, conversation: conversation, message_type: :outgoing) }

      it 'does not override data_url with external_url' do
        attachment = outgoing_message.attachments.new(account_id: account.id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).not_to eq('https://instagram.com/image.jpg')
      end
    end

    context 'when inbox is Channel::Instagram (direct login)' do
      let(:instagram_channel) { create(:channel_instagram, account: account) }
      let(:direct_inbox) { instagram_channel.inbox }
      let(:conversation) { create(:conversation, account: account, inbox: direct_inbox) }
      let(:incoming_message) { create(:message, account: account, inbox: direct_inbox, conversation: conversation, message_type: :incoming) }

      it 'uses external_url for data_url and thumb_url' do
        attachment = incoming_message.attachments.new(account_id: account.id, file_type: :image, external_url: 'https://instagram.com/image.jpg')
        attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
        attachment.save!

        event_data = attachment.push_event_data
        expect(event_data[:data_url]).to eq('https://instagram.com/image.jpg')
        expect(event_data[:thumb_url]).to eq('https://instagram.com/image.jpg')
      end
    end
  end

  describe 'push_event_data for ig_reel attachments' do
    it 'returns external_url as data_url when no file is attached' do
      attachment = message.attachments.create!(
        account_id: message.account_id,
        file_type: :ig_reel,
        external_url: 'https://www.facebook.com/reel/123456'
      )

      event_data = attachment.push_event_data
      expect(event_data[:data_url]).to eq('https://www.facebook.com/reel/123456')
      expect(event_data[:thumb_url]).to eq('')
    end

    it 'returns file_url as data_url when file is attached' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :ig_reel,
                                           external_url: 'https://www.instagram.com/reel/123')
      attachment.file.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png', content_type: 'image/png')
      attachment.save!

      event_data = attachment.push_event_data
      expect(event_data[:data_url]).to be_present
    end
  end

  describe 'push_event_data for embed attachments' do
    it 'returns external url as data_url' do
      attachment = message.attachments.create!(account_id: message.account_id, file_type: :embed, external_url: 'https://example.com/embed')

      expect(attachment.push_event_data[:data_url]).to eq('https://example.com/embed')
    end
  end

  describe 'set_extension' do
    it 'sets extension from filename on save' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')
      attachment.save!

      expect(attachment.extension).to eq('pdf')
    end

    it 'does not overwrite extension if already set' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file, extension: 'doc')
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')
      attachment.save!

      expect(attachment.extension).to eq('doc')
    end

    it 'handles filenames without extension' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake data'), filename: 'README', content_type: 'text/plain')
      attachment.save!

      expect(attachment.extension).to be_nil
    end
  end

  describe 'push_event_data includes extension and content_type' do
    it 'returns extension and content_type for file attachments' do
      attachment = message.attachments.new(account_id: message.account_id, file_type: :file)
      attachment.file.attach(io: StringIO.new('fake pdf'), filename: 'test.pdf', content_type: 'application/pdf')
      attachment.save!

      event_data = attachment.push_event_data
      expect(event_data[:extension]).to eq('pdf')
      expect(event_data[:content_type]).to eq('application/pdf')
    end
  end

  describe 'file size validation' do
    let(:attachment) { message.attachments.new(account_id: message.account_id, file_type: :image) }

    before do
      allow(GlobalConfigService).to receive(:load).and_call_original
    end

    it 'respects configured limit' do
      allow(GlobalConfigService).to receive(:load)
        .with('MAXIMUM_FILE_UPLOAD_SIZE', 40)
        .and_return('5')

      attachment.errors.clear
      attachment.send(:validate_file_size, 4.megabytes)

      expect(attachment.errors[:file]).to be_empty

      attachment.errors.clear
      attachment.send(:validate_file_size, 6.megabytes)

      expect(attachment.errors[:file]).to include('size is too big')
    end

    it 'falls back to default when configured limit is invalid' do
      allow(GlobalConfigService).to receive(:load)
        .with('MAXIMUM_FILE_UPLOAD_SIZE', 40)
        .and_return('-10')

      attachment.errors.clear
      attachment.send(:validate_file_size, 41.megabytes)

      expect(attachment.errors[:file]).to include('size is too big')
    end
  end
end
