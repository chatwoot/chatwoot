module Unicode
  module DisplayWidth
    VERSION = '1.8.0'
    UNICODE_VERSION = "14.0.0"
    DATA_DIRECTORY = File.expand_path(File.dirname(__FILE__) + '/../../../data/').freeze
    INDEX_FILENAME = (DATA_DIRECTORY + '/display_width.marshal.gz').freeze
  end
end
