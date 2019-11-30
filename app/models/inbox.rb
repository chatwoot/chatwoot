# frozen_string_literal: true

# == Schema Information
#
# Table name: inboxes
#
#  id           :integer          not null, primary key
#  channel_type :string
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :integer          not null
#  channel_id   :integer          not null
#
# Indexes
#
#  index_inboxes_on_account_id  (account_id)
#

class Inbox < ApplicationRecord
  validates :account_id, presence: true

  belongs_to :account

  # TODO: should add associations for the channel types
  belongs_to :channel, polymorphic: true, dependent: :destroy

  has_many :contact_inboxes, dependent: :destroy
  has_many :contacts, through: :contact_inboxes

  has_many :inbox_members, dependent: :destroy
  has_many :members, through: :inbox_members, source: :user
  has_many :conversations, dependent: :destroy
  has_many :messages, through: :conversations
  after_create :subscribe_webhook, if: :facebook?
  after_destroy :delete_round_robin_agents

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

  def next_available_agent
    user_id = Redis::Alfred.rpoplpush(round_robin_key, round_robin_key)
    account.users.find_by(id: user_id)
  end

  private

  def delete_round_robin_agents
    Redis::Alfred.delete(round_robin_key)
  end

  def round_robin_key
    format(Constants::RedisKeys::ROUND_ROBIN_AGENTS, inbox_id: id)
  end

  def subscribe_webhook
    Facebook::Messenger::Subscriptions.subscribe(
      access_token: channel.page_access_token,
      subscribed_fields: %w[
        message_mention messages messaging_account_linking messaging_checkout_updates
        message_echoes message_deliveries messaging_game_plays messaging_optins messaging_optouts
        messaging_payments messaging_postbacks messaging_pre_checkouts message_reads messaging_referrals
        messaging_handovers messaging_policy_enforcement messaging_page_feedback
        messaging_appointments messaging_direct_sends
      ]
    )
  end
end
