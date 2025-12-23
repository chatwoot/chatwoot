# frozen_string_literal: true

module Unicode
  class DisplayWidth
    VERSION = "3.1.4"
    UNICODE_VERSION = "16.0.0"
    DATA_DIRECTORY = File.expand_path(File.dirname(__FILE__) + "/../../../data/")
    INDEX_FILENAME = DATA_DIRECTORY + "/display_width.marshal.gz"
  end
end
