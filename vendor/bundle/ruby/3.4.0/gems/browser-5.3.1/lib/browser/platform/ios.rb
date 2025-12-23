# frozen_string_literal: true

module Browser
  class Platform
    class IOS < Base
      MATCHER = /(iPhone|iPad|iPod)/.freeze
      VERSION_MATCHER =
        /OS (?<major>\d+)_(?<minor>\d+)_?(?<patch>\d+)?/.freeze

      def version
        matches = VERSION_MATCHER.match(ua)

        return "0" unless matches

        versions = [matches[:major]]

        if matches[:patch]
          versions.push(matches[:minor], matches[:patch])
        else
          versions.push(matches[:minor]) unless matches[:minor] == "0"
        end

        versions.join(".")
      end

      def name
        "iOS (#{device})"
      end

      def id
        :ios
      end

      def match?
        ua.match?(MATCHER)
      end

      def device
        ua[MATCHER, 1]
      end
    end
  end
end
