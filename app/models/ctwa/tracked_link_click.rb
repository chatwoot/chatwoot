# == Schema Information
#
# Table name: ctwa_tracked_link_clicks
#
#  id              :bigint           not null, primary key
#  expires_at      :datetime         not null
#  params          :jsonb            not null
#  token           :string           not null
#  user_agent      :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint
#  tracked_link_id :bigint           not null
#
# Indexes
#
#  idx_ctwa_tracked_link_clicks_account       (account_id)
#  idx_ctwa_tracked_link_clicks_conversation  (conversation_id)
#  idx_ctwa_tracked_link_clicks_link          (tracked_link_id)
#  idx_ctwa_tracked_link_clicks_link_created  (tracked_link_id,created_at)
#  idx_ctwa_tracked_link_clicks_token         (token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#  fk_rails_...  (conversation_id => conversations.id) ON DELETE => nullify
#  fk_rails_...  (tracked_link_id => ctwa_tracked_links.id) ON DELETE => cascade
#
class Ctwa::TrackedLinkClick < ApplicationRecord
  self.table_name = 'ctwa_tracked_link_clicks'

  TOKEN_FORMAT = /\A[A-Z2-9]{8}\z/
  TRACKING_PARAM_KEYS = %w[
    gclid
    fbclid
    ttclid
    utm_source
    utm_medium
    utm_campaign
    utm_term
    utm_content
  ].freeze

  belongs_to :account
  belongs_to :tracked_link, class_name: 'Ctwa::TrackedLink'
  belongs_to :conversation, optional: true

  before_validation :generate_token, on: :create
  before_validation :set_expires_at, on: :create
  before_validation :normalize_params
  # prepend: ApplicationRecord's generic validates_column_content_length runs earlier in the
  # chain and would flag the untruncated value before this callback shortens it.
  before_validation :truncate_user_agent, prepend: true

  validates :token, presence: true, uniqueness: true, format: { with: TOKEN_FORMAT }
  validates :expires_at, presence: true
  validate :params_must_be_hash

  scope :active, -> { where(conversation_id: nil).where('expires_at > ?', Time.current) }

  private

  def generate_token
    return if token.present?

    alphabet = Ctwa::TrackedLink::CODE_ALPHABET
    loop do
      self.token = Array.new(8) { alphabet[SecureRandom.random_number(alphabet.length)] }.join
      break unless self.class.exists?(token: token)
    end
  end

  def set_expires_at
    self.expires_at ||= 72.hours.from_now
  end

  def normalize_params
    return if params.blank?
    return unless params.respond_to?(:to_h)

    self.params = params.to_h.stringify_keys.slice(*TRACKING_PARAM_KEYS).each_with_object({}) do |(key, value), normalized|
      next unless value.is_a?(String)
      next if value.blank?

      normalized[key] = value.first(512)
    end
  end

  def truncate_user_agent
    return if user_agent.blank?

    self.user_agent = user_agent.first(255)
  end

  def params_must_be_hash
    return if params.is_a?(Hash)

    errors.add(:params, 'must be a hash')
  end
end
