# frozen_string_literal: true

module Haml
  module Helpers
    @@action_view_defined = true

    # This module contains various useful helper methods
    # that either tie into ActionView or the rest of the ActionPack stack,
    # or are only useful in that context.
    # Thus, the methods defined here are only available
    # if ActionView is installed.
    module ActionViewExtensions
      # Returns a value for the "class" attribute
      # unique to this controller/action pair.
      # This can be used to target styles specifically at this action or controller.
      # For example, if the current action were `EntryController#show`,
      #
      #     %div{:class => page_class} My Div
      #
      # would become
      #
      #     <div class="entry show">My Div</div>
      #
      # Then, in a stylesheet (shown here as [Sass](http://sass-lang.com)),
      # you could refer to this specific action:
      #
      #     .entry.show
      #       font-weight: bold
      #
      # or to all actions in the entry controller:
      #
      #     .entry
      #       color: #00f
      #
      # @return [String] The class name for the current page
      def page_class
        "#{controller.controller_name} #{controller.action_name}"
      end
      alias_method :generate_content_class_names, :page_class

      # Treats all input to \{Haml::Helpers#haml\_concat} within the block
      # as being HTML safe for Rails' XSS protection.
      # This is useful for wrapping blocks of code that concatenate HTML en masse.
      #
      # This has no effect if Rails' XSS protection isn't enabled.
      #
      # @yield A block in which all input to `#haml_concat` is treated as raw.
      # @see Haml::Util#rails_xss_safe?
      def with_raw_haml_concat
        old = instance_variable_defined?(:@_haml_concat_raw) ? @_haml_concat_raw : false
        @_haml_concat_raw = true
        yield
      ensure
        @_haml_concat_raw = old
      end
    end

    include ActionViewExtensions
  end
end
