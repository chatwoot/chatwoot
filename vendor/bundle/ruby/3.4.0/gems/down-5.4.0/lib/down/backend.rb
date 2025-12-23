# frozen-string-literal: true

require "down/version"
require "down/chunked_io"
require "down/errors"
require "down/utils"

require "fileutils"

module Down
  class Backend
    def self.download(*args, **options, &block)
      new.download(*args, **options, &block)
    end

    def self.open(*args, **options, &block)
      new.open(*args, **options, &block)
    end

    private

    # If destination path is defined, move tempfile to the destination,
    # otherwise return the tempfile unchanged.
    def download_result(tempfile, destination)
      return tempfile unless destination

      tempfile.close # required for Windows
      FileUtils.mv tempfile.path, destination

      nil
    end

    def normalize_headers(response_headers)
      response_headers.inject({}) do |headers, (downcased_name, value)|
        name = downcased_name.split("-").map(&:capitalize).join("-")
        headers.merge!(name => value)
      end
    end
  end
end
