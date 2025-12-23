require 'sprockets/exporters/zlib_exporter'

module Sprockets
  module Exporters
    # Generates a `.gz` file using the zopfli algorithm from the
    # Zopfli gem.
    class ZopfliExporter < ZlibExporter
      def setup
        @gzip_target = "#{ target }.gz"
        @gzip = Sprockets::Utils::Gzip.new(asset, archiver: Utils::Gzip::ZopfliArchiver)
      end
    end
  end
end
