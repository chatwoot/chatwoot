# frozen_string_literal: true

require 'nokogiri'
require 'open-uri'
require 'httparty'

class AppleMessagesForBusiness::OpenGraphParserService
  def initialize(url)
    @url = normalize_url(url)
  end

  def parse
    return default_data unless valid_url?

    begin
      doc = fetch_document
      extract_open_graph_data(doc)
    rescue StandardError => e
      Rails.logger.error "OpenGraph parsing failed for #{@url}: #{e.message}"
      default_data
    end
  end

  private

  # Normalize URL by adding protocol if missing
  def normalize_url(url)
    return url if url.blank?

    # Already has protocol
    return url if url.match?(%r{\Ahttps?://})

    # Add https:// for www. and domain.tld patterns
    if url.match?(/\A(www\.|[a-zA-Z0-9-]+\.[a-zA-Z]{2,})/)
      "https://#{url}"
    else
      url
    end
  end

  def valid_url?
    @url.present? && @url.match?(%r{\Ahttps?://})
  end

  def fetch_document
    # Use Safari User Agent to avoid blocking
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15'
    }

    html = URI.open(@url, headers).read
    Nokogiri::HTML(html)
  end

  def extract_open_graph_data(doc)
    {
      success: true,
      title: extract_title(doc),
      description: extract_description(doc),
      image_url: extract_image_url(doc),
      favicon_url: extract_favicon_url(doc),
      url: @url,
      site_name: extract_site_name(doc)
    }
  end

  def extract_title(doc)
    # Try OpenGraph title first
    og_title = doc.at_css('meta[property="og:title"]')&.[]('content')
    return og_title if og_title.present?

    # Fallback to page title
    page_title = doc.at_css('title')&.text
    return page_title if page_title.present?

    # Final fallback to domain name
    extract_domain_name
  end

  def extract_description(doc)
    # Try OpenGraph description
    og_desc = doc.at_css('meta[property="og:description"]')&.[]('content')
    return og_desc if og_desc.present?

    # Fallback to meta description
    meta_desc = doc.at_css('meta[name="description"]')&.[]('content')
    return meta_desc if meta_desc.present?

    nil
  end

  def extract_image_url(doc)
    # Try OpenGraph image
    og_image = doc.at_css('meta[property="og:image"]')&.[]('content')
    return make_absolute_url(og_image) if og_image.present?

    # Try Twitter Card image
    twitter_image = doc.at_css('meta[name="twitter:image"]')&.[]('content')
    return make_absolute_url(twitter_image) if twitter_image.present?

    # Try to find the largest image on the page
    images = doc.css('img[src]')
    largest_image = images.max_by do |img|
      width = img['width']&.to_i || 0
      height = img['height']&.to_i || 0
      width * height
    end

    return make_absolute_url(largest_image['src']) if largest_image

    # Fallback to favicon as the last resort
    favicon_url = extract_favicon_url(doc)
    return favicon_url if favicon_url.present?

    nil
  end

  # Extract favicon URL from various possible sources
  def extract_favicon_url(doc)
    # Try different favicon link rel attributes in order of preference
    favicon_selectors = [
      'link[rel="apple-touch-icon"]',           # High-res Apple touch icon
      'link[rel="apple-touch-icon-precomposed"]', # Precomposed Apple icon
      'link[rel="icon"][sizes]',                # Sized favicon (usually higher quality)
      'link[rel="shortcut icon"]',              # Traditional shortcut icon
      'link[rel="icon"]'                        # Standard icon
    ]

    favicon_selectors.each do |selector|
      favicon_link = doc.at_css(selector)
      if favicon_link&.[]('href')
        favicon_url = make_absolute_url(favicon_link['href'])
        return favicon_url if favicon_url.present?
      end
    end

    # Final fallback: standard /favicon.ico path
    uri = URI.parse(@url)
    standard_favicon = "#{uri.scheme}://#{uri.host}/favicon.ico"

    # Verify the standard favicon exists by checking if it's accessible
    return standard_favicon if favicon_exists?(standard_favicon)

    nil
  rescue URI::InvalidURIError
    nil
  end

  # Check if a favicon URL is accessible
  def favicon_exists?(favicon_url)
    response = HTTParty.head(
      favicon_url,
      timeout: 5,
      headers: {
        'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15'
      }
    )

    response.success? && response.headers['content-type']&.start_with?('image/')
  rescue StandardError
    false
  end

  def extract_site_name(doc)
    # Try OpenGraph site name
    og_site = doc.at_css('meta[property="og:site_name"]')&.[]('content')
    return og_site if og_site.present?

    # Fallback to domain name
    extract_domain_name
  end

  def make_absolute_url(url)
    return url if url.blank? || url.start_with?('http')

    uri = URI.parse(@url)
    base_url = "#{uri.scheme}://#{uri.host}"
    base_url += ":#{uri.port}" if uri.port != 80 && uri.port != 443

    if url.start_with?('//')
      "#{uri.scheme}:#{url}"
    elsif url.start_with?('/')
      "#{base_url}#{url}"
    else
      "#{base_url}/#{url}"
    end
  rescue URI::InvalidURIError
    url
  end

  def extract_domain_name
    uri = URI.parse(@url)
    uri.host&.gsub('www.', '')&.capitalize
  rescue URI::InvalidURIError
    'Website'
  end

  def default_data
    # Try to get a favicon even when page access fails
    default_favicon = try_default_favicon

    {
      success: false,
      title: extract_domain_name || 'Rich Link',
      description: nil,
      image_url: default_favicon,
      favicon_url: default_favicon,
      url: @url,
      site_name: extract_domain_name
    }
  end

  # Attempt to get favicon when page parsing fails
  def try_default_favicon
    return nil if @url.blank?

    begin
      uri = URI.parse(@url)

      # Check for well-known domain favicon mappings first
      known_favicon = get_known_domain_favicon(uri.host)
      return known_favicon if known_favicon

      # Try common favicon paths in order of preference
      favicon_paths = [
        '/apple-touch-icon.png',           # High-quality Apple touch icon
        '/apple-touch-icon-180x180.png',   # Specific size Apple icon
        '/favicon-32x32.png',              # High-quality favicon
        '/favicon-16x16.png',              # Standard favicon
        '/favicon.ico'                     # Classic favicon
      ]

      favicon_paths.each do |path|
        favicon_url = "#{uri.scheme}://#{uri.host}#{path}"
        return favicon_url if favicon_exists?(favicon_url)
      end

      nil
    rescue URI::InvalidURIError
      nil
    end
  end

  # Get favicon for well-known domains that might block requests
  def get_known_domain_favicon(host)
    # Remove www. prefix for matching
    domain = host&.gsub('www.', '')&.downcase

    # Map of domains to their reliable favicon URLs
    # Using embedded base64 images for domains that block external requests
    domain_favicons = {
      'google.com' => get_embedded_google_icon,
      'rcsforbusiness.google' => get_embedded_google_icon,
      'github.com' => 'https://logo.clearbit.com/github.com',
      'apple.com' => 'https://logo.clearbit.com/apple.com',
      'facebook.com' => 'https://logo.clearbit.com/facebook.com',
      'instagram.com' => 'https://logo.clearbit.com/instagram.com',
      'twitter.com' => 'https://logo.clearbit.com/twitter.com',
      'x.com' => 'https://logo.clearbit.com/twitter.com',
      'linkedin.com' => 'https://logo.clearbit.com/linkedin.com',
      'youtube.com' => 'https://logo.clearbit.com/youtube.com'
    }

    # Return the mapped favicon URL if domain is known
    domain_favicons[domain]
  end

  # Embedded Google icon as base64 to avoid blocking issues
  def get_embedded_google_icon
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAdgAAAHYBTnsmCAAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAOKSURBVFiFpZdNbBNnEIafsb3+ie04cWLHJCE/pKQNbUPTpqRKQVWFVOjRUlVt6aUqvfTQaq/tpb32VHGBKlpxgfPaE5e2HCBfQEqhTVqlIdAkJARnJ/7F39/OzHdw0tCENtDPjGb2nd3nmfddhZQSf+dQABNAFIgDAeBUvV6f3O12QwghBAARQgAEEIACoLy/DqClpSUIvAvstG3bSKVSXL58GddccaPRaLz1ygJGowGAoiiIogh6vZ6qqio8Hg8cx1Eulys7Ozv30+n0q7OzswOAkX8iYH9/f7DZbPLRRx8lJiYmKBaLNBqNOXlBBBGxLIs7duxwOzo6/AMDA8f6+voGgC+B2FsFBEH4UNO0Y4cOHSKdThMMBoNOp5N/eY9bCaF+LpcDXVe5fPmy6PcLB/v7+08Cn5VKJf1VBbq6unqLxeLnTqfzlNvtbjMMQ79TIymlIKaJGQqhFgrYu3cjC4VC6sKlixcCgcDHwCfPFIjH4xHTNE/c6oTT6dzYyskoaP8Utra2IqRkZGSEQABkpcK5cxdObty4cbq3t3fm/wLRaDQE3Gp/MBjMaZpm/xOB3a0SHnf/fhXhcLhkWdZfCUSj0TfK5XIun8/ns9lsVtOy+Hw+ysjVq1fZ2NjIDxkZBweHh+Hs2bNYlnUsHAof/GbSpBCCcDhcamtrE4ODg8+oVqtDNE1TLpfL1Wo1H43Gg0KI8fHx8pdfLxQKhQJer9fW6/VnysrKWLBgwePLly/LdDrdnE4nbzJJPTvnz5/Htm373NzcHIoQAs/HM7z++uv4fD40TfOqqqoKIYQihEAIQT6f5+bNm5RKJSzLQgjBnDlzaG9vZ/LkyXXXdR0hBFJKJiYmSCQSZDIZGo0GACmlKrq6upgxY4aUUuJyubAsC5fLxaxZs5BSNg8GbGdn50HTNLl69SqiKBIOh8nlcgB/nAyEEAQCAa5cucLy5ctZtXoVo6OjTW/vu+8+Ll269M9PBgjBsmXLpJQyz549fP/9zN70vn37mDp1aiQcDtu9vb3YjgMiAiJAkydPFrquS5fLJSORCHPnzsXn8/H48ROsW7fOiV20hAaOb4yOjjI8PIy79i62baOqKpZlIYRgamtrSdd1KaVE13VaW1uJRCIMDw1z9OjR7FtvvfXMGWjtCNfX1z18dOjInKamJhRFwXVdFEVBVVWy2Szj4+PPPAjAayAXQaZhGPrExMT9Usp5wLxnu5ckVykTrQI6oAFaAAi8+AWmAdOAmbXarv8APaUEUEJjywgAAAAASUVORK5CYII='
  end

  # Add favicon support for additional common services
  def get_service_favicon(domain)
    case domain
    when 'slack.com'
      'https://logo.clearbit.com/slack.com'
    when 'notion.so'
      'https://logo.clearbit.com/notion.so'
    when 'zoom.us'
      'https://logo.clearbit.com/zoom.us'
    when 'microsoft.com'
      'https://logo.clearbit.com/microsoft.com'
    when 'dropbox.com'
      'https://logo.clearbit.com/dropbox.com'
    else
      nil
    end
  end
end
