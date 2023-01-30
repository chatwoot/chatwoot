require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'download_url' do
    it 'returns valid download url' do
      message = create(:message)
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
      expect(attachment.download_url).not_to be_nil
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

    it 'returns external url as data and thumb urls' do
      external_url = instagram_message.attachments.first.external_url
      expect(instagram_message.attachments.first.push_event_data[:data_url]).to eq external_url
    end
  end
end
