require "spring/version"

module Spring
  module Client
    class Version < Command
      def call
        puts "Spring version #{Spring::VERSION}"
      end
    end
  end
end
