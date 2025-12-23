# frozen_string_literal: true

module Datadog
  module Core
    module Environment
      # Reports Ruby VM cache performance statistics.
      # This currently encompasses cache invalidation counters and is CRuby-specific.
      #
      # JRuby emulates some CRuby global cache statistics, but they are synthetic and don't
      # provide actionable performance information in the same way CRuby does.
      # @see https://github.com/jruby/jruby/issues/4384#issuecomment-267069314
      #
      # TruffleRuby does not have a global runtime cache invalidation cache.
      # @see http://archive.today/2021.09.10-205702/https://medium.com/graalvm/precise-method-and-constant-invalidation-in-truffleruby-4dd56c6bac1a
      module VMCache
        module_function

        # Global constant cache "generation" counter.
        #
        # Whenever a constant creation busts the global constant cache
        # this value is incremented. This has a measurable performance impact
        # and thus show be avoided after application warm up.
        #
        # This was removed in Ruby 3.2.
        # @see https://github.com/ruby/ruby/blob/master/doc/NEWS/NEWS-3.2.0.md#implementation-improvements
        def global_constant_state
          ::RubyVM.stat[:global_constant_state]
        end

        # Global method cache "generation" counter.
        #
        # Whenever a method creation busts the global method cache
        # this value is incremented. This has a measurable performance impact
        # and thus show be avoided after application warm up.
        #
        # Since Ruby 3.0, the method class is kept on a per-class basis,
        # largely mitigating global method cache busting. `global_method_state`
        # is thus not available since Ruby 3.0.
        # @see https://bugs.ruby-lang.org/issues/16614
        def global_method_state
          ::RubyVM.stat[:global_method_state]
        end

        # Introduced in Ruby 3.2 to match an improved cache implementation.
        #
        # @see https://bugs.ruby-lang.org/issues/18589
        def constant_cache_invalidations
          ::RubyVM.stat[:constant_cache_invalidations]
        end

        # Introduced in Ruby 3.2 to match an improved cache implementation.
        #
        # @see https://bugs.ruby-lang.org/issues/18589
        def constant_cache_misses
          ::RubyVM.stat[:constant_cache_misses]
        end

        def available?
          defined?(::RubyVM) && ::RubyVM.respond_to?(:stat)
        end
      end
    end
  end
end
