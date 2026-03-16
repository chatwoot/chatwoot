require 'rails_helper'

RSpec.describe ReusableAttachment do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'requires name' do
      reusable_attachment = account.reusable_attachments.new(name: nil)
      expect(reusable_attachment.valid?).to be false
      expect(reusable_attachment.errors[:name]).to include("can't be blank")
    end

    it 'requires file' do
      reusable_attachment = account.reusable_attachments.new(name: 'Test File')
      expect(reusable_attachment.valid?).to be false
      expect(reusable_attachment.errors[:file]).to include("can't be blank")
    end

    it 'validates file size' do
      allow(GlobalConfigService).to receive(:load)
        .with('MAXIMUM_FILE_UPLOAD_SIZE', '40')
        .and_return('1')

      reusable_attachment = account.reusable_attachments.new(name: 'Large File')
      reusable_attachment.file.attach(
        io: StringIO.new('x' * 2.megabytes),
        filename: 'large.pdf',
        content_type: 'application/pdf'
      )

      expect(reusable_attachment.valid?).to be false
      expect(reusable_attachment.errors[:file]).to include('size should be less than 1MB')
    end
  end

  describe 'file metadata' do
    it 'sets file_type from content_type' do
      reusable_attachment = account.reusable_attachments.new(name: 'Test Image')
      reusable_attachment.file.attach(
        io: Rails.root.join('spec/assets/avatar.png').open,
        filename: 'avatar.png',
        content_type: 'image/png'
      )
      reusable_attachment.save!

      expect(reusable_attachment.file_type).to eq('image')
    end

    it 'sets extension from filename' do
      reusable_attachment = account.reusable_attachments.new(name: 'Test PDF')
      reusable_attachment.file.attach(
        io: StringIO.new('fake pdf'),
        filename: 'document.pdf',
        content_type: 'application/pdf'
      )
      reusable_attachment.save!

      expect(reusable_attachment.extension).to eq('pdf')
    end
  end

  describe 'URL methods' do
    let(:reusable_attachment) do
      attachment = account.reusable_attachments.new(name: 'Test Image')
      attachment.file.attach(
        io: Rails.root.join('spec/assets/avatar.png').open,
        filename: 'avatar.png',
        content_type: 'image/png'
      )
      attachment.save!
      attachment
    end

    it 'returns file_url' do
      expect(reusable_attachment.file_url).to be_present
    end

    it 'returns download_url' do
      expect(reusable_attachment.download_url).to be_present
    end

    it 'returns thumb_url for images' do
      expect(reusable_attachment.thumb_url).to be_present
    end

    it 'returns nil thumb_url for non-images' do
      pdf_attachment = account.reusable_attachments.new(name: 'Test PDF')
      pdf_attachment.file.attach(
        io: StringIO.new('fake pdf'),
        filename: 'test.pdf',
        content_type: 'application/pdf'
      )
      pdf_attachment.save!

      expect(pdf_attachment.thumb_url).to be_nil
    end
  end

  describe 'as_json' do
    it 'returns complete JSON representation' do
      # Create a fresh account to avoid state pollution
      fresh_account = create(:account)
      attachment = fresh_account.reusable_attachments.new(
        name: 'Test PDF',
        description: 'Test description'
      )
      attachment.file.attach(
        io: StringIO.new('fake pdf content'),
        filename: 'document.pdf',
        content_type: 'application/pdf'
      )
      attachment.save!

      json = attachment.as_json

      expect(json[:id]).to eq(attachment.id)
      expect(json[:name]).to eq('Test PDF')
      expect(json[:description]).to eq('Test description')
      expect(json[:file_type]).to eq('file')
      expect(json[:extension]).to eq('pdf')
      expect(json[:file_url]).to be_present
      expect(json[:download_url]).to be_present
      expect(json[:file_size]).to be_present
    end
  end
end
