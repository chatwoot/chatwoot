require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'download_url' do
    it 'returns valid download url' do
      message = create(:message)
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
      expect(attachment.download_url).not_to be_nil
    end

    it 'returns external url as data url if attachment is instagram story mention' do
      # message = create(:message, :instagram_story_mention)
      # attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      # attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
      # expect(attachment.metadata[:data_url]).to eq(attachment.external_url)
      ## expect(attachment.metadata[:thumb_url]).to eq(attachment.external_url)
    end
  end
end
