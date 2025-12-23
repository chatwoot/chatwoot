require 'sprockets/exporters/base'

module Sprockets
  module Exporters
    # Writes a an asset file to disk
    class FileExporter < Exporters::Base
      def skip?(logger)
        if ::File.exist?(target)
          logger.debug "Skipping #{ target }, already exists"
          true
        else
          logger.info "Writing #{ target }"
          false
        end
      end

      def call
        write(target) do |file|
          file.write(asset.source)
        end
      end
    end
  end
end
