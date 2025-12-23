# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module LanguageSupport
    extend self

    @@forkable = nil
    def can_fork?
      # this is expensive to check, so we should only check once
      return @@forkable if !@@forkable.nil?

      @@forkable = Process.respond_to?(:fork)
    end

    def gc_profiler_usable?
      defined?(::GC::Profiler) && !jruby?
    end

    def gc_profiler_enabled?
      gc_profiler_usable? && ::GC::Profiler.enabled? && !::NewRelic::Agent.config[:disable_gc_profiler]
    end

    def object_space_usable?
      if jruby?
        require 'jruby'
        JRuby.runtime.is_object_space_enabled
      else
        defined?(::ObjectSpace)
      end
    end

    def jruby?
      RUBY_ENGINE == 'jruby'
    end

    # TODO: OLD RUBIES - RUBY_VERSION < 2.6
    #
    # Ruby 2.6 introduced an improved version of `Object.const_get` that
    # respects the full namespace of the input and doesn't just grab the first
    # constant matching the string to the right of the last '::'.
    # Once we drop support for Ruby 2.5 and below, the only value this custom
    # method will provide beyond `Object.const_get` itself is to automatically
    # catch NameError.
    #
    # see: https://github.com/rails/rails/commit/7057ccf6565c1cb5354c1906880119276a9d15c0
    #
    # With Ruby 2.6+, this method can be defined like so:
    # def constantize(constant_as_string_or_symbol)
    #   Object.const_get(constant_as_string_or_symbol)
    # rescue NameError
    # end
    #
    def constantize(const_name)
      const_name.to_s.sub(/\A::/, '').split('::').inject(Object) do |namespace, name|
        begin
          result = namespace.const_get(name)

          # const_get looks up the inheritance chain, so if it's a class
          # in the constant make sure we found the one in our namespace.
          #
          # Can't help if the constant isn't a class...
          if result.is_a?(Module)
            expected_name = "#{namespace}::#{name}".gsub(/^Object::/, '')
            return unless expected_name == result.to_s
          end

          result
        rescue NameError
          nil
        end
      end
    end

    def camelize(string)
      camelized = string.downcase
      camelized.split(/\-|\_/).map(&:capitalize).join
    end

    def camelize_with_first_letter_downcased(string)
      camelized = camelize(string)
      camelized[0].downcase.concat(camelized[1..-1])
    end

    def snakeize(string)
      string.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end

    def bundled_gem?(gem_name)
      defined?(Bundler) && Bundler.rubygems.all_specs.map(&:name).include?(gem_name)
    rescue => e
      ::NewRelic::Agent.logger.info("Could not determine if third party #{gem_name} gem is installed", e)
      false
    end
  end
end
