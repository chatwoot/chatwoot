# frozen_string_literal: true

module Browser
  class SamsungBrowser < Chrome
    def id
      :samsung_browser
    end

    def name
      "Samsung Browser"
    end

    def full_version
      ua[%r{SamsungBrowser/([\d.]+)}, 1] || super
    end

    def match?
      ua.include?("SamsungBrowser")
    end
  end
end
