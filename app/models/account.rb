# == Schema Information
#
# Table name: accounts
#
#  id                    :integer          not null, primary key
#  auto_resolve_duration :integer
#  domain                :string(100)
#  feature_flags         :integer          default(0), not null
#  locale                :integer          default("en")
#  name                  :string           not null
#  settings_flags        :integer          default(0), not null
#  support_email         :string(100)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class Account < ApplicationRecord
  # used for single column multi flags
  include FlagShihTzu
  include Reportable
  include Featurable

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  ACCOUNT_SETTINGS_FLAGS = {
    1 => :custom_email_domain_enabled
  }.freeze

  validates :name, presence: true
  validates :auto_resolve_duration, numericality: { greater_than_or_equal_to: 1, allow_nil: true }

  has_many :account_users, dependent: :destroy
  has_many :agent_bot_inboxes, dependent: :destroy
  has_many :agent_bots, dependent: :destroy
  has_many :csat_survey_responses, dependent: :destroy
  has_many :data_imports, dependent: :destroy
  has_many :users, through: :account_users
  has_many :inboxes, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :contacts, dependent: :destroy
  has_many :facebook_pages, dependent: :destroy, class_name: '::Channel::FacebookPage'
  has_many :telegram_bots, dependent: :destroy
  has_many :twilio_sms, dependent: :destroy, class_name: '::Channel::TwilioSms'
  has_many :twitter_profiles, dependent: :destroy, class_name: '::Channel::TwitterProfile'
  has_many :web_widgets, dependent: :destroy, class_name: '::Channel::WebWidget'
  has_many :email_channels, dependent: :destroy, class_name: '::Channel::Email'
  has_many :api_channels, dependent: :destroy, class_name: '::Channel::Api'
  has_many :line_channels, dependent: :destroy, class_name: '::Channel::Line'
  has_many :telegram_channels, dependent: :destroy, class_name: '::Channel::Telegram'
  has_many :canned_responses, dependent: :destroy
  has_many :webhooks, dependent: :destroy
  has_many :labels, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :hooks, dependent: :destroy, class_name: 'Integrations::Hook'
  has_many :working_hours, dependent: :destroy
  has_many :kbase_portals, dependent: :destroy, class_name: '::Kbase::Portal'
  has_many :kbase_categories, dependent: :destroy, class_name: '::Kbase::Category'
  has_many :kbase_articles, dependent: :destroy, class_name: '::Kbase::Article'
  has_many :teams, dependent: :destroy
  has_many :custom_filters, dependent: :destroy
  has_many :custom_attribute_definitions, dependent: :destroy

  has_flags ACCOUNT_SETTINGS_FLAGS.merge(column: 'settings_flags').merge(DEFAULT_QUERY_SETTING)

  enum locale: LANGUAGES_CONFIG.map { |key, val| [val[:iso_639_1_code], key] }.to_h

  after_create_commit :notify_creation

  def agents
    users.where(account_users: { role: :agent })
  end

  def administrators
    users.where(account_users: { role: :administrator })
  end

  def all_conversation_tags
    # returns array of tags
    conversation_ids = conversations.pluck(:id)
    ActsAsTaggableOn::Tagging.includes(:tag)
                             .where(context: 'labels',
                                    taggable_type: 'Conversation',
                                    taggable_id: conversation_ids)
                             .map { |_| _.tag.name }
  end

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  def inbound_email_domain
    domain || GlobalConfig.get('MAILER_INBOUND_EMAIL_DOMAIN')['MAILER_INBOUND_EMAIL_DOMAIN'] || ENV.fetch('MAILER_INBOUND_EMAIL_DOMAIN', false)
  end

  def support_email
    super || GlobalConfig.get('MAILER_SUPPORT_EMAIL')['MAILER_SUPPORT_EMAIL'] || ENV.fetch('MAILER_SENDER_EMAIL', 'Chatwoot <accounts@chatwoot.com>')
  end

  private

  def notify_creation
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CREATED, Time.zone.now, account: self)
  end

  trigger.after(:insert).for_each(:row) do
    "execute format('create sequence IF NOT EXISTS conv_dpid_seq_%s', NEW.id);"
  end

  trigger.name('camp_dpid_before_insert').after(:insert).for_each(:row) do
    "execute format('create sequence IF NOT EXISTS camp_dpid_seq_%s', NEW.id);"
  end
end
