# frozen_string_literal: true

module Browser
  class Snapchat < Base
    def id
      :snapchat
    end

    def name
      "Snapchat"
    end

    def full_version
      ua[%r{Snapchat( ?|/)([\d.]+)}, 2] || "0.0"
    end

    def match?
      ua.include?("Snapchat")
    end
  end
end
