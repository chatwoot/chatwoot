# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                            :integer          not null, primary key
#  allow_messages_after_resolved :boolean          default(TRUE)
#  auto_assignment_config        :jsonb
#  business_name                 :string
#  channel_type                  :string
#  csat_config                   :jsonb            not null
#  csat_survey_enabled           :boolean          default(FALSE)
#  email_address                 :string
#  enable_auto_assignment        :boolean          default(TRUE)
#  enable_email_collect          :boolean          default(TRUE)
#  greeting_enabled              :boolean          default(FALSE)
#  greeting_message              :string
#  lock_to_single_conversation   :boolean          default(FALSE), not null
#  name                          :string           not null
#  out_of_office_message         :string
#  sender_name_type              :integer          default("friendly"), not null
#  timezone                      :string           default("UTC")
#  working_hours_enabled         :boolean          default(FALSE)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  account_id                    :integer          not null
#  channel_id                    :integer          not null
#  portal_id                     :bigint
#
# Indexes
#
#  index_inboxes_on_account_id                   (account_id)
#  index_inboxes_on_channel_id_and_channel_type  (channel_id,channel_type)
#  index_inboxes_on_portal_id                    (portal_id)
#
# Foreign Keys
#
#  fk_rails_...  (portal_id => portals.id)
#

class Inbox < ApplicationRecord
  include Reportable
  include Avatarable
  include OutOfOffisable
  include AccountCacheRevalidator

  # Not allowing characters:
  validates :name, presence: true
  validates :name, if: :check_channel_type?, format: { with: %r{^^\b[^/\\<>@]*\b$}, multiline: true,
                                                       message: I18n.t('errors.inboxes.validations.name') }
  validates :account_id, presence: true
  validates :timezone, inclusion: { in: TZInfo::Timezone.all_identifiers }
  validates :out_of_office_message, length: { maximum: Limits::OUT_OF_OFFICE_MESSAGE_MAX_LENGTH }
  validates :greeting_message, length: { maximum: Limits::GREETING_MESSAGE_MAX_LENGTH }
  validate :ensure_valid_max_assignment_limit

  belongs_to :account
  belongs_to :portal, optional: true

  belongs_to :channel, polymorphic: true, dependent: :destroy

  has_many :campaigns, dependent: :destroy_async
  has_many :contact_inboxes, dependent: :destroy_async
  has_many :contacts, through: :contact_inboxes

  has_many :inbox_members, dependent: :destroy_async
  has_many :members, through: :inbox_members, source: :user
  has_many :conversations, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async

  has_one :agent_bot_inbox, dependent: :destroy_async
  has_one :agent_bot, through: :agent_bot_inbox
  has_many :webhooks, dependent: :destroy_async
  has_many :hooks, dependent: :destroy_async, class_name: 'Integrations::Hook'

  enum sender_name_type: { friendly: 0, professional: 1 }

  after_destroy :delete_round_robin_agents

  after_create_commit :dispatch_create_event
  after_update_commit :dispatch_update_event

  scope :order_by_name, -> { order('lower(name) ASC') }

  # Adds multiple members to the inbox
  # @param user_ids [Array<Integer>] Array of user IDs to add as members
  # @return [void]
  def add_members(user_ids)
    inbox_members.create!(user_ids.map { |user_id| { user_id: user_id } })
    update_account_cache
  end

  # Removes multiple members from the inbox
  # @param user_ids [Array<Integer>] Array of user IDs to remove
  # @return [void]
  def remove_members(user_ids)
    inbox_members.where(user_id: user_ids).destroy_all
    update_account_cache
  end

  def sms?
    channel_type == 'Channel::Sms'
  end

  def facebook?
    channel_type == 'Channel::FacebookPage'
  end

  def instagram?
    (facebook? || instagram_direct?) && channel.instagram_id.present?
  end

  def instagram_direct?
    channel_type == 'Channel::Instagram'
  end

  def web_widget?
    channel_type == 'Channel::WebWidget'
  end

  def api?
    channel_type == 'Channel::Api'
  end

  def email?
    channel_type == 'Channel::Email'
  end

  def twilio?
    channel_type == 'Channel::TwilioSms'
  end

  def twitter?
    channel_type == 'Channel::TwitterProfile'
  end

  def whatsapp?
    channel_type == 'Channel::Whatsapp'
  end

  def assignable_agents
    (account.users.where(id: members.select(:user_id)) + account.administrators).uniq
  end

  def active_bot?
    agent_bot_inbox&.active? || hooks.where(app_id: %w[dialogflow],
                                            status: 'enabled').count.positive?
  end

  def inbox_type
    channel.name
  end

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  def callback_webhook_url
    host = ENV.fetch('FRONTEND_URL', nil)
    case channel_type
    when 'Channel::TwilioSms'
      "#{host}/twilio/callback"
    when 'Channel::Sms'
      "#{host}/webhooks/sms/#{channel.phone_number.delete_prefix('+')}"
    when 'Channel::Line'
      "#{host}/webhooks/line/#{channel.line_channel_id}"
    when 'Channel::Whatsapp'
      host = ENV.fetch('INTERNAL_HOST_URL', nil) if channel.use_internal_host?
      "#{host}/webhooks/whatsapp/#{channel.phone_number}"
    end
  end

  def member_ids_with_assignment_capacity
    members.ids
  end

  private

  def dispatch_create_event
    return if ENV['ENABLE_INBOX_EVENTS'].blank?

    Rails.configuration.dispatcher.dispatch(INBOX_CREATED, Time.zone.now, inbox: self)
  end

  def dispatch_update_event
    return if ENV['ENABLE_INBOX_EVENTS'].blank?

    Rails.configuration.dispatcher.dispatch(INBOX_UPDATED, Time.zone.now, inbox: self, changed_attributes: previous_changes)
  end

  def ensure_valid_max_assignment_limit
    # overridden in enterprise/app/models/enterprise/inbox.rb
  end

  def delete_round_robin_agents
    ::AutoAssignment::InboxRoundRobinService.new(inbox: self).clear_queue
  end

  def check_channel_type?
    ['Channel::Email', 'Channel::Api', 'Channel::WebWidget'].include?(channel_type)
  end
end

Inbox.prepend_mod_with('Inbox')
Inbox.include_mod_with('Audit::Inbox')
Inbox.include_mod_with('Concerns::Inbox')
