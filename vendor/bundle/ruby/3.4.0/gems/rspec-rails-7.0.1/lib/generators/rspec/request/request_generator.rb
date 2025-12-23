require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class RequestGenerator < Base
      class_option :request_specs, type: :boolean, default: true, desc: 'Generate request specs'

      def generate_request_spec
        return unless options[:request_specs]

        template 'request_spec.rb',
                 target_path('requests', "#{name.underscore.pluralize}_spec.rb")
      end
    end
  end
end
