require 'database_cleaner/version'
require 'database_cleaner/cleaners'
require 'forwardable'

module DatabaseCleaner
  class << self
    extend Forwardable
    delegate [
      :[],
      :strategy=,
      :start,
      :clean,
      :clean_with,
      :cleaning,
    ] => :cleaners

    attr_accessor :allow_remote_database_url, :allow_production, :url_allowlist

    alias :url_whitelist :url_allowlist
    alias :url_whitelist= :url_allowlist=

    def cleaners
      @cleaners ||= Cleaners.new
    end
    attr_writer :cleaners
  end
end
