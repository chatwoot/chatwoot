# == Schema Information
#
# Table name: channel_web_widgets
#
#  id                    :integer          not null, primary key
#  continuity_via_email  :boolean          default(TRUE), not null
#  feature_flags         :integer          default(3), not null
#  hmac_mandatory        :boolean          default(FALSE)
#  hmac_token            :string
#  pre_chat_form_enabled :boolean          default(FALSE)
#  pre_chat_form_options :jsonb
#  reply_time            :integer          default("in_a_few_minutes")
#  website_token         :string
#  website_url           :string
#  welcome_tagline       :string
#  welcome_title         :string
#  widget_color          :string           default("#1f93ff")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :integer
#
# Indexes
#
#  index_channel_web_widgets_on_hmac_token     (hmac_token) UNIQUE
#  index_channel_web_widgets_on_website_token  (website_token) UNIQUE
#

class Channel::WebWidget < ApplicationRecord
  include Channelable
  include FlagShihTzu

  self.table_name = 'channel_web_widgets'
  EDITABLE_ATTRS = [:website_url, :widget_color, :welcome_title, :welcome_tagline, :reply_time, :pre_chat_form_enabled,
                    :continuity_via_email, :hmac_mandatory,
                    { pre_chat_form_options: [:pre_chat_message, :require_email] },
                    { selected_feature_flags: [] }].freeze

  validates :website_url, presence: true
  validates :widget_color, presence: true

  has_secure_token :website_token
  has_secure_token :hmac_token

  has_flags 1 => :attachments,
            2 => :emoji_picker,
            :column => 'feature_flags',
            :check_for_column => false

  enum reply_time: { in_a_few_minutes: 0, in_a_few_hours: 1, in_a_day: 2 }

  def name
    'Website'
  end

  def web_widget_script
    "
    <script>
      (function(d,t) {
        var BASE_URL=\"#{ENV.fetch('FRONTEND_URL', '')}\";
        var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
        g.src=BASE_URL+\"/packs/js/sdk.js\";
        g.defer = true;
        g.async = true;
        s.parentNode.insertBefore(g,s);
        g.onload=function(){
          window.chatwootSDK.run({
            websiteToken: '#{website_token}',
            baseUrl: BASE_URL
          })
        }
      })(document,\"script\");
    </script>
    "
  end

  def create_contact_inbox(additional_attributes = {})
    ActiveRecord::Base.transaction do
      contact = inbox.account.contacts.create!(
        name: ::Haikunator.haikunate(1000),
        additional_attributes: additional_attributes
      )
      contact_inbox = ::ContactInbox.create!(
        contact_id: contact.id,
        inbox_id: inbox.id,
        source_id: SecureRandom.uuid
      )
      contact_inbox
    rescue StandardError => e
      Rails.logger.info e
    end
  end
end
