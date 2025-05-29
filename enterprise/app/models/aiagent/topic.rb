# == Schema Information
#
# Table name: aiagent_topics
#
#  id          :bigint           not null, primary key
#  config      :jsonb            not null
#  description :string
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
# Indexes
#
#  index_aiagent_topics_on_account_id  (account_id)
#
class Aiagent::Topic < ApplicationRecord
  include Avatarable

  self.table_name = 'aiagent_topics'

  belongs_to :account
  has_many :documents, class_name: 'Aiagent::Document', dependent: :destroy_async
  has_many :responses, class_name: 'Aiagent::TopicResponse', dependent: :destroy_async
  has_many :aiagent_inboxes,
           class_name: 'AiagentInbox',
           foreign_key: :aiagent_topic_id,
           dependent: :destroy_async
  has_many :inboxes,
           through: :aiagent_inboxes
  has_many :messages, as: :sender, dependent: :nullify

  validates :name, presence: true
  validates :description, presence: true
  validates :account_id, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }

  def available_name
    name
  end

  def push_event_data
    {
      id: id,
      name: name,
      avatar_url: avatar_url.presence || default_avatar_url,
      description: description,
      created_at: created_at,
      type: 'aiagent_topic'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      avatar_url: avatar_url.presence || default_avatar_url,
      description: description,
      created_at: created_at,
      type: 'aiagent_topic'
    }
  end

  private

  def default_avatar_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/assets/images/dashboard/aiagent/logo.svg"
  end
end
