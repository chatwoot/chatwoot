# frozen_string_literal: true

module Parser
  module Color
    def self.color(str, code, bold: false)
      return str unless STDOUT.tty?
      code = Array(code)
      code.unshift(1) if bold
      "\e[#{code.join(';')}m#{str}\e[0m"
    end

    def self.red(str, bold: false)
      color(str, 31, bold: bold)
    end

    def self.green(str, bold: false)
      color(str, 32, bold: bold)
    end

    def self.yellow(str, bold: false)
      color(str, 33, bold: bold)
    end

    def self.magenta(str, bold: false)
      color(str, 35, bold: bold)
    end

    def self.underline(str)
      color(str, 4)
    end
  end
end
