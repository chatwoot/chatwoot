module Hashie
  module Extensions
    module Mash
      # Allow a Mash to properly respond to everything
      #
      # By default, Mashes only say they respond to methods for keys that exist
      # in their key set or any of the affix methods (e.g. setter, underbang,
      # etc.). This causes issues when you try to use them within a
      # SimpleDelegator or bind to a method for a key that is unset.
      #
      # This extension allows a Mash to properly respond to `respond_to?` and
      # `method` for keys that have not yet been set. This enables full
      # compatibility with SimpleDelegator and thunk-oriented programming.
      #
      # There is a trade-off with this extension: it will run slower than a
      # regular Mash; insertions and initializations with keys run approximately
      # 20% slower and cost approximately 19KB of memory per class that you
      # make permissive.
      #
      # @api public
      # @example Make a new, permissively responding Mash subclass
      #   class PermissiveMash < Hashie::Mash
      #     include Hashie::Extensions::Mash::PermissiveRespondTo
      #   end
      #
      #   mash = PermissiveMash.new(a: 1)
      #   mash.respond_to? :b  #=> true
      module PermissiveRespondTo
        # The Ruby hook for behavior when including the module
        #
        # @api private
        # @private
        # @return void
        def self.included(base)
          base.instance_variable_set :@_method_cache, base.instance_methods
          base.define_singleton_method(:method_cache) { @_method_cache }
        end

        # The Ruby hook for determining what messages a class might respond to
        #
        # @api private
        # @private
        def respond_to_missing?(_method_name, _include_private = false)
          true
        end

        private

        # Override the Mash logging behavior to account for permissiveness
        #
        # @api private
        # @private
        def log_collision?(method_key)
          self.class.method_cache.include?(method_key) &&
            !self.class.disable_warnings?(method_key) &&
            !(regular_key?(method_key) || regular_key?(method_key.to_s))
        end
      end
    end
  end
end
