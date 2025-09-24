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
#  phone                  :string
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
  include UserAttributeHelpers

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable,
         :confirmable,
         :password_has_required_content,
         :omniauthable, omniauth_providers: [:google_oauth2]

  # TODO: remove in a future version once online status is moved to account users
  # remove the column availability from users
  enum availability: { online: 0, offline: 1, busy: 2 }

  # The validation below has been commented out as it does not
  # work because :validatable in devise overrides this.
  # validates_uniqueness_of :email, scope: :account_id

  validates :email, presence: true

  has_many :transactions, dependent: :nullify

  has_many :account_users, dependent: :destroy_async
  has_many :accounts, through: :account_users
  accepts_nested_attributes_for :account_users

  has_many :assigned_conversations, foreign_key: 'assignee_id', class_name: 'Conversation', dependent: :nullify, inverse_of: :assignee
  alias_attribute :conversations, :assigned_conversations
  has_many :csat_survey_responses, foreign_key: 'assigned_agent_id', dependent: :nullify, inverse_of: :assigned_agent
  has_many :conversation_participants, dependent: :destroy_async
  has_many :participating_conversations, through: :conversation_participants, source: :conversation

  has_many :inbox_members, dependent: :destroy_async
  has_many :inboxes, through: :inbox_members, source: :inbox
  has_many :messages, as: :sender, dependent: :nullify
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
  has_many :articles, foreign_key: 'author_id', dependent: :nullify, inverse_of: :author
  has_many :portal_members, class_name: :PortalMember, dependent: :destroy_async
  has_many :portals, through: :portal_members, source: :portal,
                     class_name: :Portal,
                     dependent: :nullify
  # rubocop:disable Rails/HasManyOrHasOneDependent
  # we are handling this in `remove_macros` callback
  has_many :macros, foreign_key: 'created_by_id', inverse_of: :created_by
  # rubocop:enable Rails/HasManyOrHasOneDependent

  before_validation :set_password_and_uid, on: :create
  after_destroy :remove_macros

  scope :order_by_full_name, -> { order('lower(name) ASC') }

  before_validation do
    self.email = email.try(:downcase)
  end

  def send_devise_notification(notification, *args)
    devise_mailer.with(account: Current.account).send(notification, self, *args).deliver_later
  end

  def set_password_and_uid
    self.uid = email
  end

  def assigned_inboxes
    administrator? ? Current.account.inboxes : inboxes.where(account_id: Current.account.id)
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

  def self.from_email(email)
    find_by(email: email&.downcase)
  end

  # OTP associations and methods
  has_many :otps, dependent: :destroy

  # OTP Methods
  def generate_otp(purpose = 'email_verification', expires_in_minutes = 5, request = nil)
    Rails.logger.info "Generating OTP for user #{id} with purpose: #{purpose}"
    begin
      otp = Otp.generate_for_user(self, purpose, expires_in_minutes, request)
      Rails.logger.info "OTP generated successfully: #{otp.id}"
      otp
    rescue => e
      Rails.logger.error "Failed to generate OTP: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def verify_otp(code, purpose = 'email_verification')
    Rails.logger.info "Verifying OTP for user #{id}: code=#{code}, purpose=#{purpose}"
    
    # Find the OTP record for this user and purpose (should be only one due to upsert)
    otp_record = otps.for_purpose(purpose).first
    
    unless otp_record
      Rails.logger.warn "No OTP found for user #{id} with purpose #{purpose}"
      return { success: false, error: 'No OTP found for this user' }
    end
    
    # Check if code matches
    unless otp_record.code == code
      Rails.logger.warn "OTP code mismatch for user #{id}: expected=#{otp_record.code}, provided=#{code}"
      return { success: false, error: 'Invalid OTP code' }
    end
    
    # Check if already verified
    if otp_record.verified?
      Rails.logger.warn "OTP already used for user #{id}"
      return { success: false, error: 'OTP code has already been used' }
    end
    
    # Check if expired
    if otp_record.expired?
      Rails.logger.warn "OTP expired for user #{id}: expires_at=#{otp_record.expires_at}, current=#{Time.current}"
      return { success: false, error: 'OTP code has expired' }
    end
    
    # OTP is valid, proceed with verification
    Rails.logger.info "OTP is valid for user #{id}, proceeding with verification"
    
    if purpose == 'email_verification'
      # Confirm the user when verifying email
      confirm unless confirmed?
      Rails.logger.info "User #{id} email confirmed"
    end

    # Mark OTP as verified
    if otp_record.verify!
      Rails.logger.info "OTP successfully verified for user #{id}"
      { success: true, error: nil }
    else
      Rails.logger.error "Failed to mark OTP as verified for user #{id}"
      { success: false, error: 'Failed to verify OTP' }
    end
  end

  def otp_valid?(code, purpose = 'email_verification')
    Otp.find_valid_otp(self, code, purpose).present?
  end

  def has_pending_otp?(purpose = 'email_verification')
    otps.active.for_purpose(purpose).valid.exists?
  end

  def latest_otp(purpose = 'email_verification')
    otps.for_purpose(purpose).order(created_at: :desc).first
  end

  # Check if email is verified (using Devise confirmable)
  def email_verified?
    confirmed_at.present?
  end

  private

  def remove_macros
    macros.personal.destroy_all
  end

  belongs_to :active_subscription, class_name: 'Subscription', optional: true

  def assign_subscription(subscription)
    update(active_subscription: subscription, subscription_status: subscription.status)
  end

  def has_active_subscription?
    active_subscription.present? && active_subscription.active?
  end
end

User.include_mod_with('Audit::User')
User.include_mod_with('Concerns::User')
