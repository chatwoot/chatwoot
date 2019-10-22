class AddPicToInboxMigration < ActiveRecord::Migration[5.0]
  def change
    FacebookPage.find_each do |inbox|
      begin
        url = 'http://graph.facebook.com/' << inbox.page_id << '/picture?type=large'
        uri = URI.parse(url)
        tries = 3
        begin
          response = uri.open(redirect: false)
        rescue OpenURI::HTTPRedirect => e
          uri = e.uri # assigned from the "Location" response header
          retry if (tries -= 1) > 0
          raise
        end
        pic_url = response.base_uri.to_s
        puts pic_url.inspect
      rescue StandardError => e
        pic_url = nil
      end
      inbox.remote_avatar_url = pic_url
      inbox.save!
    end
  end
end
