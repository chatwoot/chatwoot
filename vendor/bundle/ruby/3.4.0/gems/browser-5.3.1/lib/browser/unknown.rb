# frozen_string_literal: true

module Browser
  class Unknown < Base
    NAMES = {
      "QuickTime" => "QuickTime",
      "CoreMedia" => "Apple CoreMedia"
    }.freeze

    def id
      :unknown_browser
    end

    def name
      infer_name || "Unknown Browser"
    end

    def full_version
      ua[%r{(?:QuickTime)/([\d.]+)}, 1] ||
        ua[/CoreMedia v([\d.]+)/, 1] ||
        "0.0"
    end

    def match?
      true
    end

    private def infer_name
      (NAMES.find {|key, _| ua.include?(key) } || []).last
    end
  end
end
