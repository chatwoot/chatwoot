module Channel
  class WebWidget < ApplicationRecord
    self.table_name = 'channel_web_widgets'

    validates :website_name, presence: true
    validates :website_url, presence: true

    belongs_to :account
    has_one :inbox, as: :channel, dependent: :destroy
    has_secure_token :website_token

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
