# frozen_string_literal: true

module SassC
  class Sass2Scss
    def self.convert(sass)
      Native.sass2scss(sass, 0)
    end
  end
end
