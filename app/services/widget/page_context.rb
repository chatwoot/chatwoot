require 'uri'

class Widget::PageContext
  URL_MAX_LENGTH = Limits::URL_LENGTH_LIMIT
  TITLE_MAX_LENGTH = 256
  TAB_ID_MAX_LENGTH = 64
  MAX_SEQUENCE = (2**53) - 1
  REQUIRED_KEYS = %w[url title tab_id sequence].freeze

  class InvalidError < ArgumentError; end

  def self.normalize(current_page)
    new(current_page: current_page).normalize
  end

  def initialize(conversation: nil, current_page:)
    @conversation = conversation
    @current_page = current_page
  end

  def normalize
    attributes = normalized_attributes

    missing_keys = REQUIRED_KEYS.reject { |key| attributes.key?(key) }
    raise InvalidError, 'current_page must include url, title, tab_id, and sequence' if missing_keys.any?

    {
      'url' => normalize_url(attributes['url']),
      'title' => normalize_string(attributes['title'], 'title', TITLE_MAX_LENGTH, allow_blank: true),
      'tab_id' => normalize_string(attributes['tab_id'], 'tab_id', TAB_ID_MAX_LENGTH, allow_blank: false),
      'sequence' => normalize_sequence(attributes['sequence']),
      'updated_at' => Time.current.utc.iso8601
    }
  end

  def perform
    normalized_page = normalize
    return false if @conversation.nil?

    @conversation.with_lock do
      if stale_update?(normalized_page)
        false
      else
        attributes = (@conversation.additional_attributes || {}).deep_dup
        attributes['current_page'] = normalized_page
        @conversation.update!(additional_attributes: attributes)
        true
      end
    end
  end

  private

  def normalized_attributes
    attributes = @current_page.to_h if @current_page.respond_to?(:to_h) && !@current_page.is_a?(Array)
    raise InvalidError, 'current_page must be an object' unless attributes.is_a?(Hash)

    attributes.each_with_object({}) { |(key, value), result| result[key.to_s] = value }
  end

  def normalize_string(value, key, max_length, allow_blank:)
    raise InvalidError, "current_page.#{key} must be a string" unless value.is_a?(String)
    raise InvalidError, "current_page.#{key} is too long" if value.length > max_length

    normalized = value.strip
    raise InvalidError, "current_page.#{key} must not be blank" if !allow_blank && normalized.blank?

    normalized
  end

  def normalize_url(value)
    url = normalize_string(value, 'url', URL_MAX_LENGTH, allow_blank: false)
    uri = URI.parse(url)
    valid_scheme = %w[http https].include?(uri.scheme.to_s.downcase)
    has_credentials = uri.userinfo.present? || url_authority(url).include?('@')
    unless valid_scheme && uri.host.present? && !has_credentials
      raise InvalidError, 'current_page.url must be a valid HTTP or HTTPS URL without credentials'
    end

    uri.scheme = uri.scheme.downcase
    uri.host = uri.host.downcase
    uri.query = nil
    uri.fragment = nil
    normalized = uri.to_s
    raise InvalidError, 'current_page.url is too long' if normalized.length > URL_MAX_LENGTH

    normalized
  rescue URI::Error
    raise InvalidError, 'current_page.url must be a valid HTTP or HTTPS URL without credentials'
  end

  def url_authority(url)
    url.split('://', 2).last.to_s.split(/[\/?#]/, 2).first.to_s
  end

  def normalize_sequence(value)
    sequence = if value.is_a?(Integer)
                 value
               elsif value.is_a?(String) && value.match?(/\A\d+\z/)
                 Integer(value, 10)
               end

    raise InvalidError, 'current_page.sequence must be a non-negative integer' unless sequence&.between?(0, MAX_SEQUENCE)

    sequence
  rescue ArgumentError
    raise InvalidError, 'current_page.sequence must be a non-negative integer'
  end

  def stale_update?(normalized_page)
    # A single current_page object cannot order updates from independent tabs.
    # Once the tab changes, the latest arrival wins; sequence ordering applies within that tab only.
    existing_page = @conversation.additional_attributes&.[]('current_page')
    return false unless existing_page.is_a?(Hash)
    return false unless existing_page['tab_id'].to_s == normalized_page['tab_id']

    existing_sequence = parse_existing_sequence(existing_page['sequence'])
    existing_sequence.present? && normalized_page['sequence'] <= existing_sequence
  end

  def parse_existing_sequence(value)
    return value if value.is_a?(Integer) && value.between?(0, MAX_SEQUENCE)
    return Integer(value, 10) if value.is_a?(String) && value.match?(/\A\d+\z/) && Integer(value, 10).between?(0, MAX_SEQUENCE)

    nil
  rescue ArgumentError
    nil
  end
end
