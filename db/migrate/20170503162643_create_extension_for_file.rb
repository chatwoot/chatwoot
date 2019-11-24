require 'uri'
class CreateExtensionForFile < ActiveRecord::Migration[5.0]
  def change
    add_column :attachments, :extension, :string, default: nil
    Attachment.find_each do |attachment|
      if attachment.external_url && (attachment.file_type != fallback)
        attachment.extension = begin
                                 Pathname.new(URI(attachment.external_url).path).extname
                               rescue StandardError
                                 nil
                               end
        attachment.save!
      end
    end
  end
end
