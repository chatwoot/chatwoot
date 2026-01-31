# == Schema Information
#
# Table name: captain_mcp_servers
#
#  id                 :bigint           not null, primary key
#  auth_config        :jsonb
#  auth_type          :string           default("none")
#  cached_tools       :jsonb
#  cache_refreshed_at :datetime
#  description        :text
#  enabled            :boolean          default(TRUE), not null
#  last_connected_at  :datetime
#  last_error         :text
#  name               :string           not null
#  slug               :string           not null
#  status             :string           default("disconnected")
#  url                :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#
# Indexes
#
#  index_captain_mcp_servers_on_account_id              (account_id)
#  index_captain_mcp_servers_on_account_id_and_enabled  (account_id,enabled)
#  index_captain_mcp_servers_on_account_id_and_slug     (account_id,slug) UNIQUE
#
class Captain::McpServer < ApplicationRecord
  include Concerns::McpToolable

  self.table_name = 'captain_mcp_servers'

  NAME_PREFIX = 'mcp'.freeze
  NAME_SEPARATOR = '_'.freeze

  FRONTEND_HOST = URI.parse(ENV.fetch('FRONTEND_URL', 'http://localhost:3000')).host.freeze
  DISALLOWED_HOSTS = ['localhost', /\.local\z/i].freeze

  belongs_to :account
  has_many :assistant_mcp_servers,
           class_name: 'Captain::AssistantMcpServer',
           foreign_key: :captain_mcp_server_id,
           inverse_of: :mcp_server,
           dependent: :destroy
  has_many :assistants,
           through: :assistant_mcp_servers,
           source: :assistant

  enum :auth_type, %w[none bearer api_key].index_by(&:itself), default: :none, validate: true, prefix: :auth
  enum :status, %w[disconnected connecting connected error].index_by(&:itself), default: :disconnected, prefix: :connection

  before_validation :generate_slug

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :account_id }
  validates :url, presence: true
  validate :validate_url_format

  scope :enabled, -> { where(enabled: true) }
  scope :connected, -> { where(status: 'connected') }

  def to_tool_metadata
    (cached_tools || []).map do |tool|
      {
        id: "#{slug}_#{tool['name']}",
        title: tool['name'].titleize,
        description: tool['description'],
        mcp: true,
        mcp_server_id: id,
        mcp_tool_name: tool['name']
      }
    end
  end

  def mark_connected!
    update!(
      status: 'connected',
      last_connected_at: Time.current,
      last_error: nil
    )
  end

  def mark_error!(error_message)
    update!(
      status: 'error',
      last_error: error_message
    )
  end

  def mark_disconnected!
    update!(status: 'disconnected')
  end

  private

  def generate_slug
    return if slug.present?
    return if name.blank?

    parameterized_name = name.parameterize(separator: NAME_SEPARATOR)
    base_slug = "#{NAME_PREFIX}#{NAME_SEPARATOR}#{parameterized_name}"
    self.slug = find_unique_slug(base_slug)
  end

  def find_unique_slug(base_slug)
    return base_slug unless slug_exists?(base_slug)

    5.times do
      slug_candidate = "#{base_slug}#{NAME_SEPARATOR}#{SecureRandom.alphanumeric(6).downcase}"
      return slug_candidate unless slug_exists?(slug_candidate)
    end

    raise ActiveRecord::RecordNotUnique, I18n.t('captain.mcp_server.slug_generation_failed')
  end

  def slug_exists?(candidate)
    self.class.exists?(account_id: account_id, slug: candidate)
  end

  def validate_url_format
    return if url.blank?

    uri = parse_url
    return errors.add(:url, 'must be a valid URL') unless uri

    validate_url_scheme(uri)
    validate_url_host(uri)
    validate_not_ip_address(uri)
  end

  def parse_url
    URI.parse(url)
  rescue URI::InvalidURIError
    nil
  end

  def validate_url_scheme(uri)
    return if uri.scheme == 'https'

    errors.add(:url, 'must use HTTPS protocol')
  end

  def validate_url_host(uri)
    if uri.host.blank?
      errors.add(:url, 'must have a valid hostname')
      return
    end

    if uri.host == FRONTEND_HOST
      errors.add(:url, 'cannot point to the application itself')
      return
    end

    DISALLOWED_HOSTS.each do |pattern|
      matched = pattern.is_a?(Regexp) ? uri.host =~ pattern : uri.host.downcase == pattern
      next unless matched

      errors.add(:url, 'cannot use disallowed hostname')
      break
    end
  end

  def validate_not_ip_address(uri)
    if /\A\d+\.\d+\.\d+\.\d+\z/.match?(uri.host)
      errors.add(:url, 'cannot be an IP address, must be a hostname')
      return
    end

    return unless uri.host&.include?(':')

    errors.add(:url, 'cannot be an IP address, must be a hostname')
  end
end
