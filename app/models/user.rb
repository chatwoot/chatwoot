# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  availability           :integer          default("online")
#  confirmation_sent_at   :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  display_name           :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           not null
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

  enum availability: { online: 0, offline: 1, busy: 2 }

  # The validation below has been commented out as it does not
  # work because :validatable in devise overrides this.
  # validates_uniqueness_of :email, scope: :account_id
  validates :email, :name, presence: true

  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users
  accepts_nested_attributes_for :account_users

  has_many :assigned_conversations, foreign_key: 'assignee_id', class_name: 'Conversation', dependent: :nullify
  has_many :inbox_members, dependent: :destroy
  has_many :inboxes, through: :inbox_members, source: :inbox
  has_many :messages, as: :sender
  has_many :invitees, through: :account_users, class_name: 'User', foreign_key: 'inviter_id', dependent: :nullify

  has_many :notifications, dependent: :destroy
  has_many :notification_settings, dependent: :destroy
  has_many :notification_subscriptions, dependent: :destroy

  before_validation :set_password_and_uid, on: :create

  after_create :create_access_token
  after_save :update_presence_in_redis, if: :saved_change_to_availability?

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def set_password_and_uid
    self.uid = email
  end

  def active_account_user
    account_users.order(active_at: :desc)&.first
  end

  def current_account_user
    account_users.find_by(account_id: Current.account.id) if Current.account
  end

  def display_name
    self[:display_name].presence || name
  end

  def account
    current_account_user&.account
  end

  def assigned_inboxes
    inboxes.where(account_id: Current.account.id)
  end

  def administrator?
    current_account_user&.administrator?
  end

  def agent?
    current_account_user&.agent?
  end

  def role
    current_account_user&.role
  end

  def inviter
    current_account_user&.inviter
  end

  def serializable_hash(options = nil)
    serialized_user = super(options).merge(confirmed: confirmed?)
    serialized_user
  end

  def push_event_data
    {
      id: id,
      name: name,
      avatar_url: avatar_url,
      type: 'user',
      availability_status: availability_status
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

  private

  def update_presence_in_redis
    accounts.each do |account|
      OnlineStatusTracker.set_status(account.id, id, availability)
    end
  end
end
