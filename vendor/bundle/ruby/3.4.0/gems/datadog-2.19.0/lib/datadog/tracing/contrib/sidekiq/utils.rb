# frozen_string_literal: true

require 'yaml'

require_relative '../../../core'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        # Common functionality used by both client-side and server-side tracers.
        module Utils
          protected

          # If class is wrapping something else, the interesting resource info
          # is the underlying, wrapped class, and not the wrapper. This is
          # primarily to support `ActiveJob`.
          def job_resource(job)
            if job['wrapped']
              job['wrapped'].to_s
            elsif job['class'] == 'Sidekiq::Extensions::DelayedClass'
              delay_extension_class(job).to_s
            else
              job['class'].to_s
            end
          rescue => e
            Datadog.logger.debug { "Error retrieving Sidekiq job class name (jid:#{job['jid']}): #{e}" }

            job['class'].to_s
          end

          def delay_extension_class(job)
            clazz, method = YAML.parse(job['args'].first).children.first.children

            method = method.value[1..-1] # Remove leading `:` from method symbol

            "#{clazz.value}.#{method}"
          end
        end
      end
    end
  end
end
