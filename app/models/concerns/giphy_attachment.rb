# A GIF picked from Giphy is stored as a link to Giphy rather than a copy of the file:
# `external_url` holds the GIF and `meta['giphy']` the details used to render it.
module GiphyAttachment
  extend ActiveSupport::Concern

  GIPHY_ATTRIBUTES = %w[id title url preview_url width height].freeze
  GIPHY_HOST = /\A([a-z0-9-]+\.)*giphy\.com\z/

  included do
    validate :giphy_urls, if: :giphy?
  end

  def giphy?
    meta&.key?('giphy')
  end

  # Stored files carry their own name; a Giphy GIF is named after its title.
  def display_file_name
    giphy? ? meta['giphy']['title'].presence || 'GIF' : file.filename.to_s
  end

  private

  def giphy_metadata
    giphy = meta['giphy']
    {
      data_url: external_url,
      thumb_url: giphy['preview_url'],
      width: giphy['width'],
      height: giphy['height'],
      meta: { giphy: giphy }
    }
  end

  # The links are rendered for customers, so they must point at Giphy.
  def giphy_urls
    urls = meta['giphy'].values_at('url', 'preview_url')
    return if external_url == urls.first && urls.all? { |url| giphy_url?(url) }

    errors.add(:external_url, 'must link to a Giphy GIF')
  end

  def giphy_url?(url)
    uri = URI.parse(url.to_s)
    uri.scheme == 'https' && GIPHY_HOST.match?(uri.host.to_s)
  rescue URI::InvalidURIError
    false
  end
end
