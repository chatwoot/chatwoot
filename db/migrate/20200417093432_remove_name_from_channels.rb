class RemoveNameFromChannels < ActiveRecord::Migration[6.0]
  def change
    remove_column :channel_facebook_pages, :name, :string
    remove_column :channel_twitter_profiles, :name, :string
    migrate_web_widget_name_to_inbox
    remove_column :channel_web_widgets, :website_name, :string # rubocop:disable Rails/BulkChangeTable

    add_column :channel_web_widgets, :welcome_title, :string
    add_column :channel_web_widgets, :welcome_tagline, :string
    add_column :channel_web_widgets, :agent_away_message, :string
    migrate_avatars_from_channel_to_inbox
  end

  def migrate_web_widget_name_to_inbox
    Channel::WebWidget.all.each do |widget|
      widget.inbox.name = widget.website_name
      widget.save!
    end
  end

  def migrate_avatars_from_channel_to_inbox
    Channel::FacebookPage.all.each do |facebook_page|
      avatar = facebook_page.avatar if facebook_page.avatar.present?
      avatar.record = facebook_page.inbox
      avatar.save!
    end
  end
end
