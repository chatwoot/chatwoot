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

    it 'returns external url as data and thumb urls when message is incoming' do
      external_url = instagram_message.attachments.first.external_url
      expect(instagram_message.attachments.first.push_event_data[:data_url]).to eq external_url
    end

    it 'returns original attachment url as data url if the message is outgoing' do
      message = create(:message, :instagram_story_mention, message_type: :outgoing)
      expect(message.attachments.first.push_event_data[:data_url]).not_to eq message.attachments.first.external_url
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
end
