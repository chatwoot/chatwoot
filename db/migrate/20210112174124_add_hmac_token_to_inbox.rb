class AddHmacTokenToInbox < ActiveRecord::Migration[6.0]
  def change
    add_column :channel_web_widgets, :hmac_token, :string
    add_index :channel_web_widgets, :hmac_token, unique: true
    set_up_existing_webwidgets
    add_column :contact_inboxes, :hmac_verified, :boolean, default: false
  end

  def set_up_existing_webwidgets
    ::Channel::WebWidget.find_in_batches do |webwidgets_batch|
      Rails.logger.info "migrated till #{webwidgets_batch.first.id}\n"
      webwidgets_batch.map(&:regenerate_hmac_token)
    end
  end
end
