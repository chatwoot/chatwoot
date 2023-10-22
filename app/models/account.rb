# == Schema Information
#
# Table name: accounts
#
#  id                      :integer          not null, primary key
#  auto_resolve_duration   :integer
#  coupon_code_used        :integer          default(0)
#  custom_attributes       :jsonb
#  deletion_email_reminder :integer
#  domain                  :string(100)
#  email_sent_at           :datetime
#  feature_flags           :integer          default(0), not null
#  limits                  :jsonb
#  locale                  :integer          default("en")
#  name                    :string           not null
#  status                  :integer          default("active")
#  support_email           :string(100)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_accounts_on_status  (status)
#

class Account < ApplicationRecord
  # used for single column multi flags
  include FlagShihTzu
  include Reportable
  include Featurable
  include CacheKeys

  DEFAULT_QUERY_SETTING = {
    flag_query_mode: :bit_operator,
    check_for_column: false
  }.freeze

  validates :name, presence: true
  validates :auto_resolve_duration, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 999, allow_nil: true }
  validates :domain, length: { maximum: 100 }

  has_many :account_users, dependent: :destroy_async
  has_many :agent_bot_inboxes, dependent: :destroy_async
  has_many :agent_bots, dependent: :destroy_async
  has_many :api_channels, dependent: :destroy_async, class_name: '::Channel::Api'
  has_many :articles, dependent: :destroy_async, class_name: '::Article'
  has_many :automation_rules, dependent: :destroy_async
  has_many :macros, dependent: :destroy_async
  has_many :campaigns, dependent: :destroy_async
  has_many :canned_responses, dependent: :destroy_async
  has_many :categories, dependent: :destroy_async, class_name: '::Category'
  has_many :contacts, dependent: :destroy_async
  has_many :conversations, dependent: :destroy_async
  has_many :csat_survey_responses, dependent: :destroy_async
  has_many :custom_attribute_definitions, dependent: :destroy_async
  has_many :custom_filters, dependent: :destroy_async
  has_many :dashboard_apps, dependent: :destroy_async
  has_many :data_imports, dependent: :destroy_async
  has_many :email_channels, dependent: :destroy_async, class_name: '::Channel::Email'
  has_many :facebook_pages, dependent: :destroy_async, class_name: '::Channel::FacebookPage'
  has_many :hooks, dependent: :destroy_async, class_name: 'Integrations::Hook'
  has_many :inboxes, dependent: :destroy_async
  has_many :labels, dependent: :destroy_async
  has_many :line_channels, dependent: :destroy_async, class_name: '::Channel::Line'
  has_many :mentions, dependent: :destroy_async
  has_many :messages, dependent: :destroy_async
  has_many :notes, dependent: :destroy_async
  has_many :notification_settings, dependent: :destroy_async
  has_many :notifications, dependent: :destroy_async
  has_many :portals, dependent: :destroy_async, class_name: '::Portal'
  has_many :sms_channels, dependent: :destroy_async, class_name: '::Channel::Sms'
  has_many :teams, dependent: :destroy_async
  has_many :telegram_bots, dependent: :destroy_async
  has_many :telegram_channels, dependent: :destroy_async, class_name: '::Channel::Telegram'
  has_many :twilio_sms, dependent: :destroy_async, class_name: '::Channel::TwilioSms'
  has_many :twitter_profiles, dependent: :destroy_async, class_name: '::Channel::TwitterProfile'
  has_many :users, through: :account_users
  has_many :web_widgets, dependent: :destroy_async, class_name: '::Channel::WebWidget'
  has_many :webhooks, dependent: :destroy_async
  has_many :whatsapp_channels, dependent: :destroy_async, class_name: '::Channel::Whatsapp'
  has_many :working_hours, dependent: :destroy_async
  has_many :account_billing_subscriptions, dependent: :destroy_async, class_name: '::Enterprise::AccountBillingSubscription'
  has_many :coupon_codes, dependent: :destroy_async

  has_one_attached :contacts_export

  enum locale: LANGUAGES_CONFIG.map { |key, val| [val[:iso_639_1_code], key] }.to_h
  enum deletion_email_reminder: { initial_reminder: 0, second_reminder: 1, deletion_pending: 2 }
  enum status: { active: 0, suspended: 1 }

  before_validation :validate_limit_keys
  after_create_commit :notify_creation
  after_destroy :remove_account_sequences

  def agents
    users.where(account_users: { role: :agent })
  end

  def administrators
    users.where(account_users: { role: :administrator })
  end

  def all_conversation_tags
    # returns array of tags
    conversation_ids = conversations.pluck(:id)
    ActsAsTaggableOn::Tagging.includes(:tag)
                             .where(context: 'labels',
                                    taggable_type: 'Conversation',
                                    taggable_id: conversation_ids)
                             .map { |_| _.tag.name }
  end

  def webhook_data
    {
      id: id,
      name: name
    }
  end

  def inbound_email_domain
    domain || GlobalConfig.get('MAILER_INBOUND_EMAIL_DOMAIN')['MAILER_INBOUND_EMAIL_DOMAIN'] || ENV.fetch('MAILER_INBOUND_EMAIL_DOMAIN', false)
  end

  def support_email
    super || ENV.fetch('MAILER_SENDER_EMAIL') { GlobalConfig.get('MAILER_SUPPORT_EMAIL')['MAILER_SUPPORT_EMAIL'] }
  end

  def usage_limits
    {
      agents: ChatwootApp.max_limit.to_i,
      inboxes: ChatwootApp.max_limit.to_i,
      history: ChatwootApp.max_limit.to_i,
    }
  end

  # For first-time signup
  def check_and_subscribe_for_plan(user)
    subscribe_for_plan unless has_stripe_subscription?(user)

  end

  def subscribe_for_plan(name = 'Trial', end_time = ChatwootApp.trial_plan_ending_time)
    _plan = Enterprise::BillingProduct.find_by(product_name: name)
    return unless _plan.present?

    plan_price = _plan.billing_product_prices.last
    account_billing_subscriptions.create!(billing_product_price: plan_price, current_period_end: end_time)
  end

  def has_stripe_subscription?(user)
    user_email = user.email
    Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY', nil)
    customer = Stripe::Customer.list(email: user_email)
    if customer.data.any?
      # customer with the specified email found
      stripe_customer_id = customer.data[0].id
      subscription = Stripe::Subscription.list(customer: stripe_customer_id)
      if subscription.data.any?
        subscription_price = Enterprise::BillingProductPrice.find_by(price_stripe_id: subscription['data'][0]['plan']['id'])
        if subscription_price
          # subscription present for stripe chat plan
          account_billing_subscriptions.create!(billing_product_price: subscription_price, subscription_stripe_id: subscription['data'][0]['id'],
            current_period_end: Time.at(subscription['data'][0]['current_period_end']).utc.to_datetime)
          return true
        else
          # subscription present but for any other stripe plan
          return false
        end
      else
        return false
      end
    else
      # No customer with the specified email found
      return false
    end
  end

  # Set limits for the account
  def set_limits_for_account(plan_price)
    begin
      update_columns(limits: plan_price.limits)
      puts 'Account updated successfully!'
    rescue StandardError => e
      puts "Error updating account: #{e.message}"
    end
    Account::UpdateUserAccountsBasedOnLimitsJob.perform_later(id)
  end

  #Create subscription plan for ltd accounts
  def subscribe_for_ltd_plan(coupon_code)
    partner_prefix = coupon_code.code[0,2]
    partner_name = ""
    if partner_prefix == "AS"
      partner_name = "AppSumo"
    elsif partner_prefix == "DM"
      partner_name = "DealMirror"
    elsif partner_prefix == "PG"
      partner_name = "PitchGround"
    end

    if coupon_code_used == 0
      _plan = Enterprise::BillingProduct.find_by(product_description: 'LTD for Tier 1 Plan')
      ltd_price = Enterprise::BillingProductPrice.find_by(billing_product_id: _plan.id)
      account_billing_subscriptions&.update(billing_product_price: ltd_price,current_period_end: Time.new(2050,12,31).utc.to_datetime,partner: partner_name)
      update_columns(coupon_code_used: coupon_code_used + 1)

    elsif coupon_code_used == 1 
      _plan = Enterprise::BillingProduct.find_by(product_description: 'LTD for Tier 2 Plan')
      ltd_price = Enterprise::BillingProductPrice.find_by(billing_product_id: _plan.id)
      account_billing_subscriptions&.update(billing_product_price: ltd_price,current_period_end: Time.new(2050,12,31).utc.to_datetime,partner: partner_name)
      update_columns(coupon_code_used: coupon_code_used + 1)

    elsif coupon_code_used == 2
      _plan = Enterprise::BillingProduct.find_by(product_description: 'LTD for Tier 3 Plan')
      ltd_price = Enterprise::BillingProductPrice.find_by(billing_product_id: _plan.id)
      account_billing_subscriptions&.update(billing_product_price: ltd_price,current_period_end: Time.new(2050,12,31).utc.to_datetime,partner: partner_name)
      update_columns(coupon_code_used: coupon_code_used + 1)
    end
  end

  private

  def notify_creation
    Rails.configuration.dispatcher.dispatch(ACCOUNT_CREATED, Time.zone.now, account: self)
  end

  trigger.after(:insert).for_each(:row) do
    "execute format('create sequence IF NOT EXISTS conv_dpid_seq_%s', NEW.id);"
  end

  trigger.name('camp_dpid_before_insert').after(:insert).for_each(:row) do
    "execute format('create sequence IF NOT EXISTS camp_dpid_seq_%s', NEW.id);"
  end

  def validate_limit_keys
    # method overridden in enterprise module
  end

  def remove_account_sequences
    ActiveRecord::Base.connection.exec_query("drop sequence IF EXISTS camp_dpid_seq_#{id}")
    ActiveRecord::Base.connection.exec_query("drop sequence IF EXISTS conv_dpid_seq_#{id}")
  end
end

Account.prepend_mod_with('Account')
Account.include_mod_with('Concerns::Account')
Account.include_mod_with('Audit::Account')
