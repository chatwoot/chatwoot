# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id                     :integer          not null, primary key
#  channel_type           :string
#  email_address          :string
#  enable_auto_assignment :boolean          default(TRUE)
#  greeting_enabled       :boolean          default(FALSE)
#  greeting_message       :string
#  name                   :string           not null
#  out_of_office_message  :string
#  working_hours_enabled  :boolean          default(FALSE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  channel_id             :integer          not null
#
# Indexes
#
#  index_inboxes_on_account_id  (account_id)
#

class Inbox < ApplicationRecord
  include Reportable
  include Avatarable
  include OutOfOffisable

  validates :account_id, presence: true

  belongs_to :account

  belongs_to :channel, polymorphic: true, dependent: :destroy

  has_many :contact_inboxes, dependent: :destroy
  has_many :contacts, through: :contact_inboxes

  has_many :inbox_members, dependent: :destroy
  has_many :members, through: :inbox_members, source: :user
  has_many :conversations, dependent: :destroy
  has_many :messages, through: :conversations

  has_one :agent_bot_inbox, dependent: :destroy
  has_one :agent_bot, through: :agent_bot_inbox
  has_many :webhooks, dependent: :destroy
  has_many :hooks, dependent: :destroy, class_name: 'Integrations::Hook'

  after_destroy :delete_round_robin_agents

  scope :order_by_name, -> { order('lower(name) ASC') }

  def add_member(user_id)
    member = inbox_members.new(user_id: user_id)
    member.save!
  end

  def remove_member(user_id)
    member = inbox_members.find_by(user_id: user_id)
    member.try(:destroy)
  end

  def facebook?
    channel.class.name.to_s == 'Channel::FacebookPage'
  end

  def web_widget?
    channel.class.name.to_s == 'Channel::WebWidget'
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

  private

  def delete_round_robin_agents
    ::RoundRobin::ManageService.new(inbox: self).clear_queue
  end
end
