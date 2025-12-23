module RSpec
  module Rails
    # Helpers for making instance variables available to views.
    module ViewAssigns
      # Assigns a value to an instance variable in the scope of the
      # view being rendered.
      #
      # @example
      #
      #     assign(:widget, stub_model(Widget))
      def assign(key, value)
        _encapsulated_assigns[key] = value
      end

      # Compat-shim for AbstractController::Rendering#view_assigns
      def view_assigns
        super.merge(_encapsulated_assigns)
      end

    private

      def _encapsulated_assigns
        @_encapsulated_assigns ||= {}
      end
    end
  end
end
