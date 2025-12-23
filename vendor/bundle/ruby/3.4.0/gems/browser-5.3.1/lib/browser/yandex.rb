# frozen_string_literal: true

module Browser
  class Yandex < Base
    def id
      :yandex
    end

    def name
      "Yandex"
    end

    def full_version
      ua[%r{YaBrowser/([\d.]+)}, 1] || "0.0"
    end

    def match?
      ua.include?("YaBrowser")
    end
  end
end
