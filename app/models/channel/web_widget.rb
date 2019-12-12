# == Schema Information
#
# Table name: channel_web_widgets
#
#  id            :integer          not null, primary key
#  website_name  :string
#  website_token :string
#  website_url   :string
#  widget_color  :string           default("#1f93ff")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :integer
#
# Indexes
#
#  index_channel_web_widgets_on_website_token  (website_token) UNIQUE
#

module Channel
  class WebWidget < ApplicationRecord
    self.table_name = 'channel_web_widgets'

    validates :website_name, presence: true
    validates :website_url, presence: true

    belongs_to :account
    has_one :inbox, as: :channel, dependent: :destroy
    has_secure_token :website_token

    def name
      'Website'
    end

    def create_contact_inbox
      ActiveRecord::Base.transaction do
        contact = inbox.account.contacts.create!(name: ::Haikunator.haikunate(1000))
        ::ContactInbox.create!(
          contact_id: contact.id,
          inbox_id: inbox.id,
          source_id: SecureRandom.uuid
        )
      rescue StandardError => e
        Rails.logger e
      end
    end
  end
end
