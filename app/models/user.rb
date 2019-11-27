class User < ApplicationRecord
  # Include default devise modules.
  include DeviseTokenAuth::Concerns::User
  include Events::Types
  include Pubsubable

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :confirmable

  # Used by the actionCable/PubSub Service we use for real time communications
  has_secure_token :pubsub_token

  validates_uniqueness_of :email, scope: :account_id
  validates :email, presence: true
  validates :name, presence: true
  validates :account_id, presence: true

  enum role: [:agent, :administrator]

  belongs_to :account
  belongs_to :inviter, class_name: 'User', required: false
  has_many :invitees, class_name: 'User', foreign_key: 'inviter_id', dependent: :nullify

  has_many :assigned_conversations, foreign_key: 'assignee_id', class_name: 'Conversation', dependent: :nullify
  has_many :inbox_members, dependent: :destroy
  has_many :assigned_inboxes, through: :inbox_members, source: :inbox
  has_many :messages

  before_validation :set_password_and_uid, on: :create

  accepts_nested_attributes_for :account

  after_create :notify_creation
  after_destroy :notify_deletion

  def set_password_and_uid
    self.uid = email
  end

  def serializable_hash(options = nil)
    serialized_user = super(options).merge(confirmed: confirmed?)
    serialized_user.merge(subscription: account.try(:subscription).try(:summary)) if ENV['BILLING_ENABLED']
    serialized_user
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
