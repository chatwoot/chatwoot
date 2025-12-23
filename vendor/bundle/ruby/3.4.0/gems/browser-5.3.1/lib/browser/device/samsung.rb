# frozen_string_literal: true

module Browser
  class Device
    class Samsung < Base
      REGEX = /\(Linux.*?; Android.*?; (SAMSUNG )?(SM-[A-Z0-9]+).*?\)/i.freeze

      def self.names
        @names ||= YAML.load_file(Browser.root.join("samsung.yml").to_s)
      end

      def id
        :samsung
      end

      def name
        "Samsung #{self.class.names[code] || code}"
      end

      def code
        matches && matches[2]
      end

      def matches
        @matches ||= ua.match(REGEX)
      end

      def match?
        !!matches
      end
    end
  end
end
