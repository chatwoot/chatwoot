# frozen_string_literal: true

module Browser
  class HuaweiBrowser < Base
    def id
      :huawei_browser
    end

    def name
      "Huawei Browser"
    end

    def full_version
      ua[%r{(?:HuaweiBrowser)/([\d.]+)}i, 1] || "0.0"
    end

    def match?
      ua.match?(/HuaweiBrowser/i)
    end
  end
end
