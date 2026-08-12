# == Schema Information
#
# Table name: channel_email
#
#  id                        :bigint           not null, primary key
#  email                     :string           not null
#  forward_to_email          :string           not null
#  imap_address              :string           default("")
#  imap_authentication       :string           default("plain")
#  imap_enable_ssl           :boolean          default(TRUE)
#  imap_enabled              :boolean          default(FALSE)
#  imap_fetch_error_count    :integer          default(0), not null
#  imap_fetch_paused_till    :datetime
#  imap_login                :string           default("")
#  imap_password             :string           default("")
#  imap_port                 :integer          default(0)
#  provider                  :string
#  provider_config           :jsonb
#  smtp_address              :string           default("")
#  smtp_authentication       :string           default("login")
#  smtp_domain               :string           default("")
#  smtp_enable_ssl_tls       :boolean          default(FALSE)
#  smtp_enable_starttls_auto :boolean          default(TRUE)
#  smtp_enabled              :boolean          default(FALSE)
#  smtp_login                :string           default("")
#  smtp_openssl_verify_mode  :string           default("none")
#  smtp_password             :string           default("")
#  smtp_port                 :integer          default(0)
#  verified_for_sending      :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :integer          not null
#
# Indexes
#
#  index_channel_email_on_email             (email) UNIQUE
#  index_channel_email_on_forward_to_email  (forward_to_email) UNIQUE
#

class Channel::Email < ApplicationRecord
  include Channelable
  include Reauthorizable

  AUTHORIZATION_ERROR_THRESHOLD = 10

  # TODO: Remove guard once encryption keys become mandatory (target 3-4 releases out).
  if Chatwoot.encryption_configured?
    encrypts :imap_password
    encrypts :smtp_password
  end

  self.table_name = 'channel_email'
  EDITABLE_ATTRS = [:email, :imap_enabled, :imap_login, :imap_password, :imap_address, :imap_port, :imap_enable_ssl, :imap_authentication,
                    :smtp_enabled, :smtp_login, :smtp_password, :smtp_address, :smtp_port, :smtp_domain, :smtp_enable_starttls_auto,
                    :smtp_enable_ssl_tls, :smtp_openssl_verify_mode, :smtp_authentication, :provider, :verified_for_sending].freeze

  # provider_config is deliberately excluded, routine OAuth token refreshes update it
  IMAP_SETTINGS_ATTRS = %w[imap_enabled imap_address imap_port imap_login imap_password imap_enable_ssl imap_authentication provider].freeze

  validates :email, uniqueness: true
  validates :forward_to_email, uniqueness: true

  before_validation :ensure_forward_to_email, on: :create
  before_save :clear_imap_fetch_backoff, if: :imap_settings_changed?

  def name
    'Email'
  end

  def imap_fetch_paused?
    imap_fetch_paused_till.present? && imap_fetch_paused_till.future?
  end

  # update_columns keeps internal retry bookkeeping out of audit logs
  def imap_fetch_error!
    # read the persisted count, the in-memory value can be stale on long-running jobs
    count = self.class.where(id: id).pick(:imap_fetch_error_count).to_i + 1
    update_columns(imap_fetch_error_count: count, imap_fetch_paused_till: imap_fetch_backoff_period(count)&.from_now) # rubocop:disable Rails/SkipsModelValidations
  end

  def clear_imap_fetch_backoff!
    return if imap_fetch_error_count.zero? && imap_fetch_paused_till.nil?

    update_columns(imap_fetch_error_count: 0, imap_fetch_paused_till: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def reauthorized!
    clear_imap_fetch_backoff!
    super
  end

  def microsoft?
    provider == 'microsoft'
  end

  def google?
    provider == 'google'
  end

  def legacy_google?
    imap_enabled && imap_address == 'imap.gmail.com'
  end

  private

  def ensure_forward_to_email
    self.forward_to_email ||= "#{SecureRandom.hex}@#{account.inbound_email_domain}"
  end

  # first two failures are tolerated as transient blips, 60 minutes doubles as the probe cadence
  def imap_fetch_backoff_period(count)
    case count
    when 0..2 then nil
    when 3 then 5.minutes
    when 4 then 15.minutes
    else 60.minutes
    end
  end

  def imap_settings_changed?
    changed_attribute_names_to_save.intersect?(IMAP_SETTINGS_ATTRS)
  end

  def clear_imap_fetch_backoff
    self.imap_fetch_error_count = 0
    self.imap_fetch_paused_till = nil
  end
end
