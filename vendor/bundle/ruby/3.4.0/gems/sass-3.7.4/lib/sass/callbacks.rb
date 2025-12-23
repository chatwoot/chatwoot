module Sass
  # A lightweight infrastructure for defining and running callbacks.
  # Callbacks are defined using \{#define\_callback\} at the class level,
  # and called using `run_#{name}` at the instance level.
  #
  # Clients can add callbacks by calling the generated `on_#{name}` method,
  # and passing in a block that's run when the callback is activated.
  #
  # @example Define a callback
  #   class Munger
  #     extend Sass::Callbacks
  #     define_callback :string_munged
  #
  #     def munge(str)
  #       res = str.gsub(/[a-z]/, '\1\1')
  #       run_string_munged str, res
  #       res
  #     end
  #   end
  #
  # @example Use a callback
  #   m = Munger.new
  #   m.on_string_munged {|str, res| puts "#{str} was munged into #{res}!"}
  #   m.munge "bar" #=> bar was munged into bbaarr!
  module Callbacks
    # Automatically includes {InstanceMethods}
    # when something extends this module.
    #
    # @param base [Module]
    def self.extended(base)
      base.send(:include, InstanceMethods)
    end

    protected

    module InstanceMethods
      # Removes all callbacks registered against this object.
      def clear_callbacks!
        @_sass_callbacks = {}
      end
    end

    # Define a callback with the given name.
    # This will define an `on_#{name}` method
    # that registers a block,
    # and a `run_#{name}` method that runs that block
    # (optionall with some arguments).
    #
    # @param name [Symbol] The name of the callback
    # @return [void]
    def define_callback(name)
      class_eval <<RUBY, __FILE__, __LINE__ + 1
def on_#{name}(&block)
  @_sass_callbacks = {} unless defined? @_sass_callbacks
  (@_sass_callbacks[#{name.inspect}] ||= []) << block
end

def run_#{name}(*args)
  return unless defined? @_sass_callbacks
  return unless @_sass_callbacks[#{name.inspect}]
  @_sass_callbacks[#{name.inspect}].each {|c| c[*args]}
end
private :run_#{name}
RUBY
    end
  end
end
