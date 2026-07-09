require 'ipaddr'
require 'resolv'
require 'uri'

class Autonomia::Prospecting::WebsiteScraper
  MAX_BODY_BYTES = 1.megabyte
  TIMEOUT_SECONDS = 8
  USER_AGENT = 'AutonomiaProspectingBot/1.0'.freeze
  BLOCKED_HOSTS = %w[localhost].freeze
  BLOCKED_NETWORKS = [
    IPAddr.new('0.0.0.0/8'),
    IPAddr.new('10.0.0.0/8'),
    IPAddr.new('127.0.0.0/8'),
    IPAddr.new('169.254.0.0/16'),
    IPAddr.new('172.16.0.0/12'),
    IPAddr.new('192.168.0.0/16'),
    IPAddr.new('::1/128'),
    IPAddr.new('fc00::/7'),
    IPAddr.new('fe80::/10')
  ].freeze

  Result = Struct.new(:data, keyword_init: true)

  def initialize(url:)
    @url = url.to_s.strip
  end

  def perform
    return Result.new(data: empty_payload('missing_website')) if @url.blank?

    uri = normalized_uri
    validate_uri!(uri)

    response = fetch_uri(uri)
    return Result.new(data: empty_payload("http_#{response.code}")) unless response.success?

    html = response.body.to_s.byteslice(0, MAX_BODY_BYTES)
    parse_html(html, uri)
  rescue StandardError => e
    Result.new(data: empty_payload(e.class.name.demodulize.underscore, e.message.to_s.truncate(160)))
  end

  private

  def normalized_uri
    raw = @url.match?(%r{\Ahttps?://}i) ? @url : "https://#{@url}"
    URI.parse(raw)
  end

  def validate_uri!(uri)
    raise ArgumentError, 'invalid_url' unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    raise ArgumentError, 'invalid_host' if uri.host.blank?
    raise ArgumentError, 'blocked_host' if BLOCKED_HOSTS.include?(uri.host.downcase)

    addresses_for(uri.host).each do |address|
      ip = IPAddr.new(address)
      raise ArgumentError, 'blocked_host' if BLOCKED_NETWORKS.any? { |network| network.include?(ip) }
    end
  end

  def fetch_uri(uri)
    current_uri = uri
    3.times do
      validate_uri!(current_uri)
      response = HTTParty.get(
        current_uri.to_s,
        headers: { 'User-Agent' => USER_AGENT, 'Accept' => 'text/html,application/xhtml+xml' },
        timeout: TIMEOUT_SECONDS,
        follow_redirects: false
      )
      return response unless response.code.to_i.between?(300, 399)

      location = response.headers['location'].to_s
      break if location.blank?

      current_uri = URI.join(current_uri, location)
    end

    raise ArgumentError, 'too_many_redirects'
  end

  def addresses_for(host)
    Resolv.getaddresses(host)
  rescue Resolv::ResolvError
    []
  end

  def parse_html(html, uri)
    doc = Nokogiri::HTML(html)
    text = normalized_text(doc)
    links = normalized_links(doc, uri)
    data = {
      'website' => uri.to_s,
      'title' => title_for(doc),
      'description' => meta_content(doc, 'description'),
      'email' => extract_email(text, links),
      'phone' => extract_phone(text),
      'whatsapp' => extract_whatsapp(text, links),
      'instagram' => social_link(links, 'instagram.com'),
      'facebook' => social_link(links, 'facebook.com'),
      'linkedin' => linkedin_link(links),
      'cnpj' => extract_cnpj(text),
      'source_urls' => links.first(20),
      'text_excerpt' => text.first(3000),
      'scraped_at' => Time.current.iso8601
    }.compact

    Result.new(data: data)
  end

  def normalized_text(doc)
    doc.css('script, style, noscript, svg').remove
    doc.text.to_s.gsub(/\s+/, ' ').strip
  end

  def normalized_links(doc, uri)
    doc.css('a[href], link[href]').filter_map do |node|
      href = node['href'].to_s.strip
      next if href.blank?

      URI.join(uri, href).to_s
    rescue URI::InvalidURIError
      nil
    end.uniq
  end

  def title_for(doc)
    doc.at_css('meta[property="og:title"]')&.[]('content').presence ||
      doc.at_css('title')&.text.to_s.strip.presence
  end

  def meta_content(doc, name)
    doc.at_css("meta[name=\"#{name}\"]")&.[]('content').presence ||
      doc.at_css("meta[property=\"og:#{name}\"]")&.[]('content').presence
  end

  def extract_email(text, links)
    mailto = links.find { |link| link.start_with?('mailto:') }
    return mailto.delete_prefix('mailto:').split('?').first if mailto.present?

    text.match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i)&.[](0)
  end

  def extract_phone(text)
    match = text.match(/\(?\d{2}\)?\s?\d{4,5}[-\s]?\d{4}/)
    return if match.blank?

    digits = match[0].gsub(/\D/, '')
    return unless digits.length.between?(10, 11)

    "+55#{digits}"
  end

  def extract_whatsapp(text, links)
    link = links.find { |item| item.match?(%r{(?:wa\.me|api\.whatsapp\.com)}i) }
    digits = link.to_s.match(/(?:phone=|wa\.me\/)(\+?\d{10,15})/i)&.[](1)
    return "+#{digits.gsub(/\D/, '')}" if digits.present?

    extract_phone(text) if text.match?(/whatsapp|zap/i)
  end

  def social_link(links, domain)
    links.find do |link|
      host = URI.parse(link).host.to_s.delete_prefix('www.')
      host == domain && !link.match?(%r{/share|/sharer|/intent}i)
    rescue URI::InvalidURIError
      false
    end
  end

  def linkedin_link(links)
    links.find do |link|
      uri = URI.parse(link)
      host = uri.host.to_s.delete_prefix('www.')
      host == 'linkedin.com' && uri.path.match?(%r{\A/(in|company)/}i)
    rescue URI::InvalidURIError
      false
    end
  end

  def extract_cnpj(text)
    text.match(/\b\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\b/)&.[](0)
  end

  def empty_payload(error, message = nil)
    {
      'error' => error,
      'message' => message,
      'scraped_at' => Time.current.iso8601
    }.compact
  end
end
