module CustomerChatChannel
  extend ActiveSupport::Concern

  CHAT_ATTRIBUTES = [:widget_color, :welcome_title, :welcome_tagline, :reply_time, :pre_chat_form_enabled,
                     :hmac_mandatory,
                     { pre_chat_form_options: [:pre_chat_message, :require_email,
                                               { pre_chat_fields:
                                                 [:field_type, :label, :placeholder, :name, :enabled, :type, :enabled, :required,
                                                  :locale, { values: [] }, :regex_pattern, :regex_cue] }] },
                     { selected_feature_flags: [] }].freeze

  included do
    before_validation :validate_pre_chat_options
    validates :widget_color, presence: true

    has_secure_token :hmac_token

    has_flags 1 => :attachments,
              2 => :emoji_picker,
              3 => :end_conversation,
              4 => :use_inbox_avatar_for_bot,
              5 => :allow_mobile_webview,
              6 => :multiple_conversations,
              :column => 'feature_flags',
              :check_for_column => false

    enum reply_time: { in_a_few_minutes: 0, in_a_few_hours: 1, in_a_day: 2 }
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
