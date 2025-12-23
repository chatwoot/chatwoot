# frozen_string_literal: true

module RuboCop
  class CLI
    module Command
      # Prints out url to documentation of provided cops
      # or documentation base url by default.
      # @api private
      class ShowDocsUrl < Base
        self.command_name = :show_docs_url

        def initialize(env)
          super

          @config = @config_store.for(Dir.pwd)
        end

        def run
          print_documentation_url
        end

        private

        def print_documentation_url
          puts Cop::Documentation.default_base_url if cops_array.empty?

          cops_array.each do |cop_name|
            cop = registry_hash[cop_name]
            next if cop.empty?

            url = Cop::Documentation.url_for(cop.first, @config)
            puts url if url
          end

          puts
        end

        def cops_array
          @cops_array ||= @options[:show_docs_url]
        end

        def registry_hash
          @registry_hash ||= Cop::Registry.global.to_h
        end
      end
    end
  end
end
