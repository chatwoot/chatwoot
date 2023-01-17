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
#  custom_attributes      :jsonb
#  display_name           :string
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  message_signature      :text
#  name                   :string           not null
#  provider               :string           default("email"), not null
#  pubsub_token           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  tokens                 :json
#  type                   :string
#  ui_settings            :jsonb
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
  include Avatarable
  # Include default devise modules.
  include DeviseTokenAuth::Concerns::User
  include Pubsubable
  include Rails.application.routes.url_helpers
  include Reportable
  include SsoAuthenticatable

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :confirmable,
         :password_has_required_content

  # TODO: remove in a future version once online status is moved to account users
  # remove the column availability from users
  enum availability: { online: 0, offline: 1, busy: 2 }

  # The validation below has been commented out as it does not
  # work because :validatable in devise overrides this.
  # validates_uniqueness_of :email, scope: :account_id

  validates :email, :name, presence: true
  validates_length_of :name, minimum: 1, maximum: 255

  has_many :account_users, dependent: :destroy_async
  has_many :accounts, through: :account_users
  accepts_nested_attributes_for :account_users

  has_many :assigned_conversations, foreign_key: 'assignee_id', class_name: 'Conversation', dependent: :nullify
  alias_attribute :conversations, :assigned_conversations
  has_many :csat_survey_responses, foreign_key: 'assigned_agent_id', dependent: :nullify

  has_many :inbox_members, dependent: :destroy_async
  has_many :inboxes, through: :inbox_members, source: :inbox
  has_many :messages, as: :sender
  has_many :invitees, through: :account_users, class_name: 'User', foreign_key: 'inviter_id', source: :inviter, dependent: :nullify

  has_many :custom_filters, dependent: :destroy_async
  has_many :dashboard_apps, dependent: :nullify
  has_many :mentions, dependent: :destroy_async
  has_many :notes, dependent: :nullify
  has_many :notification_settings, dependent: :destroy_async
  has_many :notification_subscriptions, dependent: :destroy_async
  has_many :notifications, dependent: :destroy_async
  has_many :team_members, dependent: :destroy_async
  has_many :teams, through: :team_members
  has_many :articles, foreign_key: 'author_id', dependent: :nullify
  has_many :portal_members, class_name: :PortalMember, dependent: :destroy_async
  has_many :portals, through: :portal_members, source: :portal,
                     class_name: :Portal,
                     dependent: :nullify
  has_many :macros, foreign_key: 'created_by_id'
  before_validation :set_password_and_uid, on: :create
  after_destroy :remove_macros

  scope :order_by_full_name, -> { order('lower(name) ASC') }

  def send_devise_notification(notification, *args)
    devise_mailer.with(account: Current.account).send(notification, self, *args).deliver_later
  end

  def set_password_and_uid
    self.uid = email
  end

  def active_account_user
    account_users.order(active_at: :desc)&.first
  end

  def current_account_user
    # We want to avoid subsequent queries in case where the association is preloaded.
    # using where here will trigger n+1 queries.
    account_users.find { |ac_usr| ac_usr.account_id == Current.account.id } if Current.account
  end

  def available_name
    self[:display_name].presence || name
  end

  # Used internally for Chatwoot in Chatwoot
  def hmac_identifier
    hmac_key = GlobalConfig.get('CHATWOOT_INBOX_HMAC_KEY')['CHATWOOT_INBOX_HMAC_KEY']
    return OpenSSL::HMAC.hexdigest('sha256', hmac_key, email) if hmac_key.present?

    ''
  end

  def account
    current_account_user&.account
  end

  def assigned_inboxes
    administrator? ? Current.account.inboxes : inboxes.where(account_id: Current.account.id)
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

  def availability_status
    current_account_user&.availability_status
  end

  def auto_offline
    current_account_user&.auto_offline
  end

  def inviter
    current_account_user&.inviter
  end

  def serializable_hash(options = nil)
    super(options).merge(confirmed: confirmed?)
  end

  def push_event_data
    {
      id: id,
      name: name,
      available_name: available_name,
      avatar_url: avatar_url,
      type: 'user',
      availability_status: availability_status,
      thumbnail: avatar_url
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

  # https://github.com/lynndylanhurley/devise_token_auth/blob/6d7780ee0b9750687e7e2871b9a1c6368f2085a9/app/models/devise_token_auth/concerns/user.rb#L45
  # Since this method is overriden in devise_token_auth it breaks the email reconfirmation flow.
  def will_save_change_to_email?
    mutations_from_database.changed?('email')
  end

  def notifications_meta(account_id)
    {
      unread_count: notifications.where(account_id: account_id, read_at: nil).count,
      count: notifications.where(account_id: account_id).count
    }
  end

  private

  def remove_macros
    macros.personal.destroy_all
  end
end
