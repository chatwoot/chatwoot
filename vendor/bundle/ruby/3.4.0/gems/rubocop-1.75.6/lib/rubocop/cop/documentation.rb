# frozen_string_literal: true

module RuboCop
  module Cop
    # Helpers for builtin documentation
    module Documentation
      module_function

      # @api private
      def department_to_basename(department)
        "cops_#{department.to_s.downcase.tr('/', '_')}"
      end

      # @api private
      def url_for(cop_class, config = nil)
        base = department_to_basename(cop_class.department)
        fragment = cop_class.cop_name.downcase.gsub(/[^a-z]/, '')
        base_url = base_url_for(cop_class, config)
        extension = extension_for(cop_class, config)

        "#{base_url}/#{base}#{extension}##{fragment}" if base_url
      end

      # @api private
      def base_url_for(cop_class, config)
        if config
          department_name = cop_class.department.to_s
          url = config.for_department(department_name)['DocumentationBaseURL']
          return url if url
        end

        default_base_url if builtin?(cop_class)
      end

      # @api private
      def extension_for(cop_class, config)
        if config
          department_name = cop_class.department
          extension = config.for_department(department_name)['DocumentationExtension']
          return extension if extension
        end

        default_extension
      end

      # @api private
      def default_base_url
        'https://docs.rubocop.org/rubocop'
      end

      # @api private
      def default_extension
        '.html'
      end

      # @api private
      def builtin?(cop_class)
        # any custom method will do
        return false unless (m = cop_class.instance_methods(false).first)

        path, _line = cop_class.instance_method(m).source_location
        path.start_with?(__dir__)
      end
    end
  end
end
