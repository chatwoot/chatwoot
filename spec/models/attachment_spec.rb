require 'rails_helper'

RSpec.describe Attachment, type: :model do
  describe 'download_url' do
    it 'returns valid download url' do
      message = create(:message)
      attachment = message.attachments.new(account_id: message.account_id, file_type: :image)
      attachment.file.attach(io: File.open(Rails.root.join('spec/assets/avatar.png')), filename: 'avatar.png', content_type: 'image/png')
      expect(attachment.download_url).not_to eq nil
    end
  end
end
