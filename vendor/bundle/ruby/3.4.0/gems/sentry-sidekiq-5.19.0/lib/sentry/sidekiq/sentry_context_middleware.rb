# frozen_string_literal: true

require 'sentry/sidekiq/context_filter'

module Sentry
  module Sidekiq
    class SentryContextServerMiddleware
      OP_NAME = "queue.sidekiq"
      SPAN_ORIGIN = "auto.queue.sidekiq"

      def call(_worker, job, queue)
        return yield unless Sentry.initialized?

        context_filter = Sentry::Sidekiq::ContextFilter.new(job)

        Sentry.clone_hub_to_current_thread
        scope = Sentry.get_current_scope
        if (user = job["sentry_user"])
          scope.set_user(user)
        end
        scope.set_tags(queue: queue, jid: job["jid"])
        scope.set_tags(build_tags(job["tags"]))
        scope.set_contexts(sidekiq: job.merge("queue" => queue))
        scope.set_transaction_name(context_filter.transaction_name, source: :task)
        transaction = start_transaction(scope, job["trace_propagation_headers"])
        scope.set_span(transaction) if transaction

        begin
          yield
        rescue
          finish_transaction(transaction, 500)
          raise
        end

        finish_transaction(transaction, 200)
        # don't need to use ensure here
        # if the job failed, we need to keep the scope for error handler. and the scope will be cleared there
        scope.clear
      end

      def build_tags(tags)
        Array(tags).each_with_object({}) { |name, tags_hash| tags_hash[:"sidekiq.#{name}"] = true }
      end

      def start_transaction(scope, env)
        options = {
          name: scope.transaction_name,
          source: scope.transaction_source,
          op: OP_NAME,
          origin: SPAN_ORIGIN
        }

        transaction = Sentry.continue_trace(env, **options)
        Sentry.start_transaction(transaction: transaction, **options)
      end

      def finish_transaction(transaction, status)
        return unless transaction

        transaction.set_http_status(status)
        transaction.finish
      end
    end

    class SentryContextClientMiddleware
      def call(_worker_class, job, _queue, _redis_pool)
        return yield unless Sentry.initialized?

        user = Sentry.get_current_scope.user
        job["sentry_user"] = user unless user.empty?
        job["trace_propagation_headers"] ||= Sentry.get_trace_propagation_headers
        yield
      end
    end
  end
end
