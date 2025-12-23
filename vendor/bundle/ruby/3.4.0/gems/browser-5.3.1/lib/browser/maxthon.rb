# frozen_string_literal: true

module Browser
  class Maxthon < Base
    def id
      :maxthon
    end

    def name
      "Maxthon"
    end

    def full_version
      ua[%r{(?:Maxthon)/([\d.]+)}i, 1] || "0.0"
    end

    def match?
      ua.match?(/Maxthon/i)
    end
  end
end
