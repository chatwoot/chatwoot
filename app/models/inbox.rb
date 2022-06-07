# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                            :integer          not null, primary key
#  allow_messages_after_resolved :boolean          default(TRUE)
#  auto_assignment_config        :jsonb
#  channel_type                  :string
#  csat_survey_enabled           :boolean          default(FALSE)
#  email_address                 :string
#  enable_auto_assignment        :boolean          default(TRUE)
#  enable_email_collect          :boolean          default(TRUE)
#  greeting_enabled              :boolean          default(FALSE)
#  greeting_message              :string
#  name                          :string           not null
#  out_of_office_message         :string
#  timezone                      :string           default("UTC")
#  working_hours_enabled         :boolean          default(FALSE)
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  account_id                    :integer          not null
#  channel_id                    :integer          not null
#
# Indexes
#
#  index_inboxes_on_account_id  (account_id)
#

class Inbox < ApplicationRecord
  include Reportable
  include Avatarable
  include OutOfOffisable

  validates :name, presence: true
  validates :account_id, presence: true
  validates :timezone, inclusion: { in: TZInfo::Timezone.all_identifiers }
  validate :ensure_valid_max_assignment_limit

  belongs_to :account

  belongs_to :channel, polymorphic: true, dependent: :destroy

  has_many :campaigns, dependent: :destroy_async
  has_many :contact_inboxes, dependent: :destroy_async
  has_many :contacts, through: :contact_inboxes

  has_many :inbox_members, dependent: :destroy_async
  has_many :members, through: :inbox_members, source: :user
  has_many :conversations, dependent: :destroy_async
  has_many :messages, through: :conversations

  has_one :agent_bot_inbox, dependent: :destroy_async
  has_one :agent_bot, through: :agent_bot_inbox
  has_many :webhooks, dependent: :destroy_async
  has_many :hooks, dependent: :destroy_async, class_name: 'Integrations::Hook'

  after_destroy :delete_round_robin_agents

  scope :order_by_name, -> { order('lower(name) ASC') }

  def add_member(user_id)
    member = inbox_members.new(user_id: user_id)
    member.save!
  end

  def remove_member(user_id)
    member = inbox_members.find_by!(user_id: user_id)
    member.try(:destroy)
  end

  def facebook?
    channel_type == 'Channel::FacebookPage'
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
    case channel_type
    when 'Channel::TwilioSms'
      "#{ENV['FRONTEND_URL']}/twilio/callback"
    when 'Channel::Sms'
      "#{ENV['FRONTEND_URL']}/webhooks/sms/#{channel.phone_number.delete_prefix('+')}"
    when 'Channel::Line'
      "#{ENV['FRONTEND_URL']}/webhooks/line/#{channel.line_channel_id}"
    end
  end

  def member_ids_with_assignment_capacity
    members.ids
  end

  private

  def ensure_valid_max_assignment_limit
    # overridden in enterprise/app/models/enterprise/inbox.rb
  end

  def delete_round_robin_agents
    ::RoundRobin::ManageService.new(inbox: self).clear_queue
  end
end

Inbox.prepend_mod_with('Inbox')
