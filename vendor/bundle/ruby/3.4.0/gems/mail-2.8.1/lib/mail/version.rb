# frozen_string_literal: true
module Mail
  module VERSION

    MAJOR = 2
    MINOR = 8
    PATCH = 1
    BUILD = nil

    STRING = [MAJOR, MINOR, PATCH, BUILD].compact.join('.')

    def self.version
      STRING
    end

  end
end
