# == Schema Information
#
# Table name: channel_web_widgets
#
#  id                    :integer          not null, primary key
#  continuity_via_email  :boolean          default(TRUE), not null
#  feature_flags         :integer          default(7), not null
#  hmac_mandatory        :boolean          default(FALSE)
#  hmac_token            :string
#  pre_chat_form_enabled :boolean          default(FALSE)
#  pre_chat_form_options :jsonb
#  reply_time            :integer          default("in_a_few_minutes")
#  typing_texts          :jsonb            default([])
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
#  index_channel_web_widgets_on_typing_texts   (typing_texts) USING gin
#  index_channel_web_widgets_on_website_token  (website_token) UNIQUE
#

class Channel::WebWidget < ApplicationRecord
  include Channelable
  include FlagShihTzu

  self.table_name = 'channel_web_widgets'
  EDITABLE_ATTRS = [:website_url, :widget_color, :welcome_title, :welcome_tagline, :reply_time, :pre_chat_form_enabled,
                    :continuity_via_email, :hmac_mandatory, { typing_texts: [] },
                    { pre_chat_form_options: [:pre_chat_message, :require_email,
                                              { pre_chat_fields:
                                                [:field_type, :label, :placeholder, :name, :enabled, :type, :enabled, :required,
                                                 :locale, { values: [] }, :regex_pattern, :regex_cue] }] },
                    { selected_feature_flags: [] }].freeze

  before_validation :validate_pre_chat_options
  before_validation :set_default_typing_texts
  validates :website_url, presence: true
  validates :widget_color, presence: true
  validate :validate_typing_texts
  has_many :portals, foreign_key: 'channel_web_widget_id', dependent: :nullify, inverse_of: :channel_web_widget

  has_secure_token :website_token
  has_secure_token :hmac_token

  has_flags 1 => :attachments,
            2 => :emoji_picker,
            3 => :end_conversation,
            4 => :use_inbox_avatar_for_bot,
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

  private

  def set_default_typing_texts
    return if typing_texts.present? && typing_texts.is_a?(Array) && typing_texts.any?

    self.typing_texts = [
      'Xin chào! Tôi có thể giúp gì cho bạn?',
      'Hỗ trợ 24/7 - Luôn sẵn sàng!',
      'Chat ngay để được tư vấn miễn phí',
      'Mooly.vn - Giải pháp AI thông minh',
      'Bạn cần hỗ trợ gì không?',
      'Nhấn để bắt đầu trò chuyện',
      'AI Assistant đang chờ bạn...',
      'Tư vấn nhanh - Phản hồi tức thì'
    ]
  end

  def validate_typing_texts
    return if typing_texts.blank?

    unless typing_texts.is_a?(Array)
      errors.add(:typing_texts, 'must be an array')
      return
    end

    if typing_texts.length > 20
      errors.add(:typing_texts, 'cannot have more than 20 texts')
    end

    typing_texts.each_with_index do |text, index|
      unless text.is_a?(String)
        errors.add(:typing_texts, "text at index #{index} must be a string")
        next
      end

      if text.length > 100
        errors.add(:typing_texts, "text at index #{index} cannot be longer than 100 characters")
      end

      if text.strip.empty?
        errors.add(:typing_texts, "text at index #{index} cannot be empty")
      end
    end
  end

  def validate_pre_chat_options
    return if pre_chat_form_options.with_indifferent_access['pre_chat_fields'].present?

    self.pre_chat_form_options = {
      pre_chat_message: 'Share your queries or comments here.',
      pre_chat_fields: [
        {
          'field_type': 'standard', 'label': 'Email Id', 'name': 'emailAddress', 'type': 'email', 'required': true, 'enabled': false
        },
        {
          'field_type': 'standard', 'label': 'Full name', 'name': 'fullName', 'type': 'text', 'required': false, 'enabled': false
        },
        {
          'field_type': 'standard', 'label': 'Phone number', 'name': 'phoneNumber', 'type': 'text', 'required': false, 'enabled': false
        }
      ]
    }
  end

  def create_contact_inbox(additional_attributes = {})
    ::ContactInboxWithContactBuilder.new({
                                           inbox: inbox,
                                           contact_attributes: { additional_attributes: additional_attributes }
                                         }).perform
  end
end
