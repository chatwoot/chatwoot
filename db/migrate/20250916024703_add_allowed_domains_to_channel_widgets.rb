class AddAllowedDomainsToChannelWidgets < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_web_widgets, :allowed_domains, :text, default: ''
  end
end
