class AddNewsletterFilterEnabledToChannelEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_email, :newsletter_filter_enabled, :boolean, default: true, null: false
  end
end
