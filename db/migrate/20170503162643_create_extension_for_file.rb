require 'uri'
class CreateExtensionForFile < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :extension, :string, default: nil
    Attachment.find_each do |attachment|
      if attachment.external_url and attachment.file_type != fallback
        attachment.extension = Pathname.new(URI(attachment.external_url).path).extname rescue nil
        attachment.save!
      end
    end
  end
end
