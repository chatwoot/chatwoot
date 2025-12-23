# frozen_string_literal: true

module Aws

  # A utility module that provides a class method that wraps
  # a method such that it generates a deprecation warning when called.
  # Given the following class:
  #
  #     class Example
  #
  #       def do_something
  #       end
  #
  #     end
  #
  # If you want to deprecate the `#do_something` method, you can extend
  # this module and then call `deprecated` on the method (after it
  # has been defined).
  #
  #     class Example
  #
  #       extend Aws::Deprecations
  #
  #       def do_something
  #       end
  #
  #       def do_something_else
  #       end
  #
  #       deprecated :do_something
  #
  #     end
  #
  # The `#do_something` method will continue to function, but will
  # generate a deprecation warning when called.
  #
  # @api private
  module Deprecations

    # @param [Symbol] method The name of the deprecated method.
    #
    # @option options [String] :message The warning message to issue
    #   when the deprecated method is called.
    #
    # @option options [String] :use The name of a method that should be used.
    #
    # @option options [String] :version The version that will remove the
    #   deprecated method.
    #
    def deprecated(method, options = {})

      deprecation_msg = options[:message] || begin
        "#################### DEPRECATION WARNING ####################\n"\
        "Called deprecated method `#{method}` of #{self}."\
        "#{" Use `#{options[:use]}` instead.\n" if options[:use]}"\
        "#{"Method `#{method}` will be removed in #{options[:version]}."\
          if options[:version]}"\
        "\n#############################################################"
      end

      alias_method(:"deprecated_#{method}", method)

      warned = false # we only want to issue this warning once

      define_method(method) do |*args, &block|
        unless warned
          warned = true
          warn(deprecation_msg + "\n" + caller.join("\n"))
        end
        send("deprecated_#{method}", *args, &block)
      end
    end

  end
end
