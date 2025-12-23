# frozen_string_literal: true

module Rainbow
  class StringUtils
    def self.wrap_with_sgr(string, codes)
      return string if codes.empty?

      seq = "\e[" + codes.join(";") + "m"

      string = string.sub(/^(\e\[([\d;]+)m)*/) { |m| m + seq }

      return string if string.end_with? "\e[0m"

      string + "\e[0m"
    end

    def self.uncolor(string)
      # See http://www.commandlinefu.com/commands/view/3584/remove-color-codes-special-characters-with-sed
      string.gsub(/\e\[[0-9;]*m/, '')
    end
  end
end
