class FixOldDtUrl < ActiveRecord::Migration[7.0]
  def change
    old_url = 'https://admin-stage.digitaltolk.se/#/'
    new_url = 'https://admin-stage.digitaltolk.net/'
    Message.where("content LIKE '%#{old_url}%'").each do |message|
      new_content = message.content
      next unless new_content.downcase.include?('booking issue')

      new_content = new_content.gsub(old_url, new_url)
      Rails.logger.debug new_content
      message.update_column(:content, new_content)
    end
  end
end
