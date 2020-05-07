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
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  uid                    :string           default(""), not null
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email)
#  index_users_on_pubsub_token          (pubsub_token) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_uid_and_provider      (uid,provider) UNIQUE
#

class User < ApplicationRecord
  include AccessTokenable
  include AvailabilityStatusable
  include Avatarable
  # Include default devise modules.
  include DeviseTokenAuth::Concerns::User
  include Events::Types
  include Pubsubable
  include Rails.application.routes.url_helpers
  include Reportable

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :confirmable

  # The validation below has been commented out as it does not
  # work because :validatable in devise overrides this.
  # validates_uniqueness_of :email, scope: :account_id
  validates :email, :name, presence: true

  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users
  accepts_nested_attributes_for :account_users

  has_many :assigned_conversations, foreign_key: 'assignee_id', class_name: 'Conversation', dependent: :nullify
  has_many :inbox_members, dependent: :destroy
  has_many :assigned_inboxes, through: :inbox_members, source: :inbox
  has_many :messages
  has_many :invitees, through: :account_users, class_name: 'User', foreign_key: 'inviter_id', dependent: :nullify

  has_many :notifications, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :notification_subscriptions, dependent: :destroy

  before_validation :set_password_and_uid, on: :create

  after_create :notify_creation, :create_access_token

  after_destroy :notify_deletion

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def set_password_and_uid
    self.uid = email
  end

  def account_user
    # FIXME : temporary hack to transition over to multiple accounts per user
    # We should be fetching the current account user relationship here.
    account_users&.first
  end

  def account
    account_user&.account
  end

  def administrator?
    account_user&.administrator?
  end

  def agent?
    account_user&.agent?
  end

  def role
    account_user&.role
  end

  def inviter
    account_user&.inviter
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
      id: id,
      name: name,
      avatar_url: avatar_url,
      type: 'user'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      email: email,
      type: 'user'
    }
  end
end
