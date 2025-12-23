# frozen_string_literal: true

module Browser
  class MiuiBrowser < Base
    def id
      :miui_browser
    end

    def name
      "Miui Browser"
    end

    def full_version
      ua[%r{MiuiBrowser/([\d.]+)}, 1] || "0.0"
    end

    def match?
      ua.include?("MiuiBrowser")
    end
  end
end
