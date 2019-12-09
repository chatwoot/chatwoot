# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           not null
#  nickname               :string
#  provider               :string           default("email"), not null
#  pubsub_token           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("agent")
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  uid                    :string           default(""), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :integer          not null
#  inviter_id             :bigint
#
# Indexes
#
#  index_users_on_email                 (email)
#  index_users_on_inviter_id            (inviter_id)
#  index_users_on_pubsub_token          (pubsub_token) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (inviter_id => users.id) ON DELETE => nullify
#

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

  # Uses active storage for the avatar
  has_one_attached :avatar

  # The validation below has been commented out as it does not
  # work because :validatable in devise overrides this.
  # validates_uniqueness_of :email, scope: :account_id
  validates :email, :name, :account_id, presence: true

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
