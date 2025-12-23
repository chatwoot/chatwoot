# frozen_string_literal: true

require "valid_email2/email_validator"

module ValidEmail2
  BLACKLIST_FILE  = "config/blacklisted_email_domains.yml"
  WHITELIST_FILE  = "config/whitelisted_email_domains.yml"
  DISPOSABLE_FILE = File.expand_path('../config/disposable_email_domains.txt', __dir__)

  class << self
    def disposable_emails
      @disposable_emails ||= load_file(DISPOSABLE_FILE)
    end

    def blacklist
      @blacklist ||= load_if_exists(BLACKLIST_FILE)
    end

    def whitelist
      @whitelist ||= load_if_exists(WHITELIST_FILE)
    end

    private

    def load_if_exists(path)
      File.exist?(path) ? load_file(path) : Set.new
    end

    def load_file(path)
      # This method MUST return a Set, otherwise the
      # performance will suffer!
      if path.end_with?(".yml")
        Set.new(YAML.load_file(path))
      else
        File.open(path, "r").each_line.each_with_object(Set.new) do |domain, set|
          set << domain.tap(&:chomp!)
        end
      end
    end
  end
end
