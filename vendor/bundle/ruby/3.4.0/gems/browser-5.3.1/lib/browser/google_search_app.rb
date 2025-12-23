# frozen_string_literal: true

module Browser
  class GoogleSearchApp < Chrome
    def id
      :google_search_app
    end

    def name
      "Google Search App"
    end

    def full_version
      ua[%r{GSA/([\d.]+\d)}, 1] || super
    end

    def match?
      ua.include?("GSA")
    end
  end
end
