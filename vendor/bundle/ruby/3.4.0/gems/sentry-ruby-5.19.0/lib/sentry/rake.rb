# frozen_string_literal: true

require "rake"
require "rake/task"

module Sentry
  module Rake
    module Application
      # @api private
      def display_error_message(ex)
        mechanism = Sentry::Mechanism.new(type: 'rake', handled: false)

        Sentry.capture_exception(ex, hint: { mechanism: mechanism }) do |scope|
          task_name = top_level_tasks.join(' ')
          scope.set_transaction_name(task_name, source: :task)
          scope.set_tag("rake_task", task_name)
        end if Sentry.initialized? && !Sentry.configuration.skip_rake_integration

        super
      end
    end
  end
end

# @api private
module Rake
  class Application
    prepend(Sentry::Rake::Application)
  end
end
