class User < ApplicationRecord
  include Events::Types
  include Pubsubable

  #validates_uniqueness_of :email, scope: :account_id
  validates :account_id, presence: true

  enum role: [:agent, :administrator]

  belongs_to :account
  belongs_to :inviter, class_name: 'User', required: false

  has_many :assigned_conversations, foreign_key: 'assignee_id', class_name: 'Conversation', dependent: :nullify
  has_many :inbox_members, dependent: :destroy
  has_many :assigned_inboxes, through: :inbox_members, source: :inbox
  has_many :messages

  belongs_to :devise_user
  delegate :email,
    :name,
    :nickname,
    :uid,
    to: :devise_user

  accepts_nested_attributes_for :account

  after_create :notify_creation
  after_destroy :notify_deletion

  def serializable_hash(options = nil)
    super(options).merge(confirmed: confirmed?, subscription: account.try(:subscription).try(:summary))
  end

  def notify_creation
    Rails.configuration.dispatcher.dispatch(AGENT_ADDED, Time.zone.now, account: account)
  end

  def notify_deletion
    Rails.configuration.dispatcher.dispatch(AGENT_REMOVED, Time.zone.now, account: account)
  end

  def push_event_data
    {
      name: name
    }
  end
end
