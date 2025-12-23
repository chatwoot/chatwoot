module Sprockets
  module Rails
    # Resolve assets referenced in CSS `url()` calls and replace them with the digested paths
    class AssetUrlProcessor
      REGEX = /url\(\s*["']?(?!(?:\#|data|http))(?<relativeToCurrentDir>\.\/)?(?<path>[^"'\s)]+)\s*["']?\)/
      def self.call(input)
        context = input[:environment].context_class.new(input)
        data    = input[:data].gsub(REGEX) do |_match|
          path = Regexp.last_match[:path]
          "url(#{context.asset_path(path)})"
        end

        context.metadata.merge(data: data)
      end
    end
  end
end
