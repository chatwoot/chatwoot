# frozen_string_literal: true

module Browser
  class Weibo < Base
    def id
      :weibo
    end

    def name
      "Weibo"
    end

    def full_version
      ua[/(?:__weibo__)([\d.]+)/i, 1] || "0.0"
    end

    def match?
      ua.match?(/__weibo__/i)
    end
  end
end
