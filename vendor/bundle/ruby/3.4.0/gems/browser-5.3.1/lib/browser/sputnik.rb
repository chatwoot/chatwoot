# frozen_string_literal: true

module Browser
  class Sputnik < Base
    def id
      :sputnik
    end

    def name
      "Sputnik"
    end

    def full_version
      ua[%r{SputnikBrowser/([\d.]+)}, 1] || "0.0"
    end

    def match?
      ua.include?("SputnikBrowser")
    end
  end
end
