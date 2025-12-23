# frozen_string_literal: true

module WebConsole
  # A context lets you get object names related to the current session binding.
  class Context
    def initialize(binding)
      @binding = binding
    end

    # Extracts entire objects which can be called by the current session unless
    # the inputs is present.
    #
    # Otherwise, it extracts methods and constants of the object specified by
    # the input.
    def extract(input = nil)
      input.present? ? local(input) : global
    end

    private

      GLOBAL_OBJECTS = [
        "instance_variables",
        "local_variables",
        "methods",
        "class_variables",
        "Object.constants",
        "global_variables"
      ]

      def global
        GLOBAL_OBJECTS.map { |cmd| eval(cmd) }
      end

      def local(input)
        [
          eval("#{input}.methods").map { |m| "#{input}.#{m}" },
          eval("#{input}.constants").map { |c| "#{input}::#{c}" },
        ]
      end

      def eval(cmd)
        @binding.eval(cmd) rescue []
      end
  end
end
