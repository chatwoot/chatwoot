# frozen-string-literal: true

require "down/version"
require "down/net_http"

module Down
  module_function

  def download(*args, **options, &block)
    backend.download(*args, **options, &block)
  end

  def open(*args, **options, &block)
    backend.open(*args, **options, &block)
  end

  # Allows setting a backend via a symbol or a downloader object.
  def backend(value = nil)
    if value.is_a?(Symbol)
      require "down/#{value}"
      @backend = Down.const_get(value.to_s.split("_").map(&:capitalize).join)
    elsif value
      @backend = value
    else
      @backend
    end
  end
end

# Set Net::HTTP as the default backend
Down.backend Down::NetHttp
