module ScoutApm
  module ErrorService
    class Payload
      attr_reader :context
      attr_reader :errors

      def initialize(context, errors)
        @context = context
        @errors = errors
      end

      # TODO: Don't use to_json since it isn't supported in Ruby 1.8.7
      def serialize
        payload = as_json.to_json
        context.logger.debug(payload)
        payload
      end

      def as_json
        serialized_errors = errors.map do |error_record|
          serialize_error_record(error_record)
        end

        {
          :notifier => "scout_apm_ruby",
          :environment => context.environment.env,
          :root => context.environment.root,
          :problems => serialized_errors,
        }
      end

      def serialize_error_record(error_record)
        {
          :exception_class => error_record.exception_class,
          :message => error_record.message,
          :request_uri => error_record.request_uri,
          :request_params => error_record.request_params,
          :request_session => error_record.request_session,
          :environment => error_record.environment,
          :trace => error_record.trace,
          :request_components => error_record.request_components,
          :context => error_record.context,
        }
      end
    end
  end
end
