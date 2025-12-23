require 'sprockets/exporters/base'
require 'sprockets/utils/gzip'

module Sprockets
  module Exporters
    # Generates a `.gz` file using the zlib algorithm built into
    # Ruby's standard library.
    class ZlibExporter < Exporters::Base
      def setup
        @gzip_target = "#{ target }.gz"
        @gzip = Sprockets::Utils::Gzip.new(asset, archiver: Utils::Gzip::ZlibArchiver)
      end

      def skip?(logger)
        return true if environment.skip_gzip?
        return true if @gzip.cannot_compress?
        if ::File.exist?(@gzip_target)
          logger.debug "Skipping #{ @gzip_target }, already exists"
          true
        else
          logger.info "Writing #{ @gzip_target }"
          false
        end
      end

      def call
        write(@gzip_target) do |file|
          @gzip.compress(file, target)
        end
      end
    end
  end
end
