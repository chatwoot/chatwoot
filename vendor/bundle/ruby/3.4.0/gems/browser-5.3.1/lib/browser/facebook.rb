# frozen_string_literal: true

module Browser
  class Facebook < Base
    def id
      :facebook
    end

    def name
      "Facebook"
    end

    def full_version
      ua[%r{FBAV/([\d.]+)}, 1] ||
        ua[%r{AppleWebKit/([\d.]+)}, 0] ||
        "0.0"
    end

    def match?
      ua.match?(/FBAV|FBAN/)
    end
  end
end
