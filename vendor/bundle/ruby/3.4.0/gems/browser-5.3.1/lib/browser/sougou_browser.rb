# frozen_string_literal: true

module Browser
  class SougouBrowser < Base
    def id
      :sougou_browser
    end

    def name
      "Sougou Browser"
    end

    # We can't get the real version on desktop device from the ua string
    def full_version
      ua[%r{(?:SogouMobileBrowser)/([\d.]+)}, 1] || "0.0"
    end

    # SogouMobileBrowser for mobile device
    # SE for desktop device
    def match?
      ua.match?(/SogouMobileBrowser/i) || ua.match?(/\bSE\b/)
    end
  end
end
