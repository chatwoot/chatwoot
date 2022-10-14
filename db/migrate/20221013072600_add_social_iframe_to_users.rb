class AddSocialIframeToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :is_social_iframe, :boolean, default: false
  end
end
