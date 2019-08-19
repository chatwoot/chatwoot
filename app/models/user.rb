class User < ApplicationRecord
  # Include default devise modules.
  include DeviseTokenAuth::Concerns::User
  include Events::Types

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  validates_uniqueness_of :email, scope: :account_id
  validates :email, presence: true
  validates :name, presence: true
  validates :account_id, presence: true

  enum role: [ :agent, :administrator ]

  belongs_to :account

  has_many :assigned_conversations, foreign_key: "assignee_id", class_name: "Conversation", dependent: :nullify
  has_many :inbox_members, dependent: :destroy
  has_many :assigned_inboxes, through: :inbox_members, source: :inbox
  has_many :messages

  before_create :set_channel
  before_validation :set_password_and_uid, on: :create

  accepts_nested_attributes_for :account

  after_create :notify_creation
  after_destroy :notify_deletion

  def set_password_and_uid
    self.uid = self.email
  end

  def serializable_hash(options = nil)
    super(options).merge(confirmed: confirmed?, subscription: account.try(:subscription).try(:summary) )
  end

  def set_channel
    begin
    self.channel = SecureRandom.hex
    end while self.class.exists?(channel: channel)
  end

  def notify_creation
    $dispatcher.dispatch(AGENT_ADDED, Time.zone.now, account: self.account)
  end

  def notify_deletion
    $dispatcher.dispatch(AGENT_REMOVED, Time.zone.now, account: self.account)
  end

  def push_event_data
    {
      name: name
    }
  end
end
