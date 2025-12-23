# frozen_string_literal: true

module WebConsole
  module Testing
    module Helper
      def self.gem_root
        Pathname(File.expand_path("../../../../", __FILE__))
      end
    end
  end
end
