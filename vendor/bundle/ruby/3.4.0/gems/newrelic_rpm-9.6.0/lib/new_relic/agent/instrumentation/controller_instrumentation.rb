# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction'
require 'new_relic/agent/instrumentation/queue_time'
require 'new_relic/agent/instrumentation/ignore_actions'

module NewRelic
  module Agent
    # @api public
    module Instrumentation
      # == NewRelic instrumentation for controller actions and tasks
      #
      # This module can also be used to capture performance information for
      # background tasks and other non-web transactions, including
      # detailed transaction traces and traced errors.
      #
      # For details on how to instrument background tasks see
      # {ClassMethods#add_transaction_tracer} and
      # {#perform_action_with_newrelic_trace}
      #
      # @api public
      #
      module ControllerInstrumentation
        def self.included(clazz) # :nodoc:
          clazz.extend(ClassMethods)
        end

        # This module is for importing stubs when the agent is disabled
        module ClassMethodsShim # :nodoc:
          def newrelic_ignore(*args); end

          def newrelic_ignore_apdex(*args); end

          def newrelic_ignore_enduser(*args); end
        end

        module Shim # :nodoc:
          def self.included(clazz)
            clazz.extend(ClassMethodsShim)
          end

          def perform_action_with_newrelic_trace(*args); yield; end
        end

        NR_DO_NOT_TRACE_KEY = :'@do_not_trace'
        NR_IGNORE_APDEX_KEY = :'@ignore_apdex'
        NR_IGNORE_ENDUSER_KEY = :'@ignore_enduser'
        NR_DEFAULT_OPTIONS = NewRelic::EMPTY_HASH

        # @api public
        module ClassMethods
          # Have NewRelic ignore actions in this controller.  Specify the actions as hash options
          # using :except and :only.  If no actions are specified, all actions are ignored.
          #
          # @api public
          #
          def newrelic_ignore(specifiers = {})
            NewRelic::Agent.record_api_supportability_metric(:newrelic_ignore)
            newrelic_ignore_aspect(NR_DO_NOT_TRACE_KEY, specifiers)
          end

          # Have NewRelic omit apdex measurements on the given actions.  Typically used for
          # actions that are not user facing or that skew your overall apdex measurement.
          # Accepts :except and :only options, as with #newrelic_ignore.
          #
          # @api public
          #
          def newrelic_ignore_apdex(specifiers = {})
            NewRelic::Agent.record_api_supportability_metric(:newrelic_ignore_apdex)
            newrelic_ignore_aspect(NR_IGNORE_APDEX_KEY, specifiers)
          end

          # @api public
          def newrelic_ignore_enduser(specifiers = {})
            NewRelic::Agent.record_api_supportability_metric(:newrelic_ignore_enduser)
            newrelic_ignore_aspect(NR_IGNORE_ENDUSER_KEY, specifiers)
          end

          def newrelic_ignore_aspect(property, specifiers = {}) # :nodoc:
            if specifiers.empty?
              self.newrelic_write_attr(property, true)
            elsif !(Hash === specifiers)
              ::NewRelic::Agent.logger.error("newrelic_#{property} takes an optional hash with :only and :except lists of actions (illegal argument type '#{specifiers.class}')")
            else
              # symbolize the incoming values
              specifiers = specifiers.inject({}) do |memo, (key, values)|
                if values.is_a?(Array)
                  memo[key] = values.map(&:to_sym)
                else
                  memo[key] = values.to_sym
                end
                memo
              end
              self.newrelic_write_attr(property, specifiers)
            end
          end

          # Should be monkey patched into the controller class implemented
          # with the inheritable attribute mechanism.
          def newrelic_write_attr(attr_name, value) # :nodoc:
            instance_variable_set(attr_name, value)
          end

          def newrelic_read_attr(attr_name) # :nodoc:
            instance_variable_get(attr_name) if instance_variable_defined?(attr_name)
          end

          # Add transaction tracing to the given method.  This will treat
          # the given method as a main entrypoint for instrumentation, just
          # like controller actions are treated by default.  Useful especially
          # for background tasks.
          #
          # Example for background job:
          #   class Job
          #     include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          #     def run(task)
          #        ...
          #     end
          #     # Instrument run so tasks show up under task.name.  Note single
          #     # quoting to defer eval to runtime.
          #     add_transaction_tracer :run, :name => '#{args[0].name}'
          #   end
          #
          # Here's an example of a controller that uses a dispatcher
          # action to invoke operations which you want treated as top
          # level actions, so they aren't all lumped into the invoker
          # action.
          #
          #   MyController < ActionController::Base
          #     include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          #     # dispatch the given op to the method given by the service parameter.
          #     def invoke_operation
          #       op = params['operation']
          #       send op
          #     end
          #     # Ignore the invoker to avoid double counting
          #     newrelic_ignore :only => 'invoke_operation'
          #     # Instrument the operations:
          #     add_transaction_tracer :print
          #     add_transaction_tracer :show
          #     add_transaction_tracer :forward
          #   end
          #
          # Here's an example of how to pass contextual information into the transaction
          # so it will appear in transaction traces:
          #
          #   class Job
          #     include NewRelic::Agent::Instrumentation::ControllerInstrumentation
          #     def process(account)
          #        ...
          #     end
          #     # Include the account name in the transaction details.  Note the single
          #     # quotes to defer eval until call time.
          #     add_transaction_tracer :process, :params => '{ :account_name => args[0].name }'
          #   end
          #
          # See NewRelic::Agent::Instrumentation::ControllerInstrumentation#perform_action_with_newrelic_trace
          # for the full list of available options.
          #
          # @api public
          #
          def add_transaction_tracer(method, options = {})
            NewRelic::Agent.record_api_supportability_metric(:add_transaction_tracer)

            traced_method, punctuation = parse_punctuation(method)
            with_method_name, without_method_name = build_method_names(traced_method, punctuation)

            if already_added_transaction_tracer?(self, with_method_name)
              ::NewRelic::Agent.logger.warn("Transaction tracer already in place for class = #{self.name}, method = #{method.to_s}, skipping")
              return
            end

            # The metric path:
            options[:name] ||= method.to_s

            code_info = NewRelic::Agent::MethodTracerHelpers.code_information(self, method)
            argument_list = generate_argument_list(options.merge(code_info))

            class_eval(<<~EOC)
              def #{with_method_name}(*args, &block)
                perform_action_with_newrelic_trace(#{argument_list.join(',')}) do
                  #{without_method_name}(*args, &block)
                 end
              end
              ruby2_keywords(:#{with_method_name}) if respond_to?(:ruby2_keywords, true)
            EOC

            visibility = NewRelic::Helper.instance_method_visibility(self, method)

            alias_method(without_method_name, method.to_s)
            alias_method(method.to_s, with_method_name)
            send(visibility, method)
            send(visibility, with_method_name)
            ::NewRelic::Agent.logger.debug("Traced transaction: class = #{self.name}, method = #{method.to_s}, options = #{options.inspect}")
          end

          def parse_punctuation(method)
            [method.to_s.sub(/([?!=])$/, ''), $1]
          end

          def generate_argument_list(options)
            options.map do |key, value|
              value = if value.is_a?(Symbol)
                value.inspect
              elsif key == :params
                value.to_s
              else
                %Q("#{value.to_s}")
              end

              %Q(:#{key} => #{value})
            end
          end

          def build_method_names(traced_method, punctuation)
            ["#{traced_method.to_s}_with_newrelic_transaction_trace#{punctuation}",
              "#{traced_method.to_s}_without_newrelic_transaction_trace#{punctuation}"]
          end

          def already_added_transaction_tracer?(target, with_method_name)
            NewRelic::Helper.instance_methods_include?(target, with_method_name)
          end
        end

        # @!parse extend ClassMethods

        class TransactionNamer
          def self.name_for(txn, traced_obj, category, options = {})
            return options[:transaction_name] if options[:transaction_name]

            "#{prefix_for_category(txn, category)}#{path_name(traced_obj, options)}"
          end

          def self.prefix_for_category(txn, category = nil)
            # the following line needs else branch coverage
            category ||= (txn && txn.category) # rubocop:disable Style/SafeNavigation
            case category
            when :controller then ::NewRelic::Agent::Transaction::CONTROLLER_PREFIX
            when :web then ::NewRelic::Agent::Transaction::CONTROLLER_PREFIX
            when :task then ::NewRelic::Agent::Transaction::TASK_PREFIX
            when :background then ::NewRelic::Agent::Transaction::TASK_PREFIX
            when :rack then ::NewRelic::Agent::Transaction::RACK_PREFIX
            when :uri then ::NewRelic::Agent::Transaction::CONTROLLER_PREFIX
            when :roda then ::NewRelic::Agent::Transaction::RODA_PREFIX
            when :sinatra then ::NewRelic::Agent::Transaction::SINATRA_PREFIX
            when :middleware then ::NewRelic::Agent::Transaction::MIDDLEWARE_PREFIX
            when :grape then ::NewRelic::Agent::Transaction::GRAPE_PREFIX
            when :rake then ::NewRelic::Agent::Transaction::RAKE_PREFIX
            when :action_cable then ::NewRelic::Agent::Transaction::ACTION_CABLE_PREFIX
            when :message then ::NewRelic::Agent::Transaction::MESSAGE_PREFIX
            else "#{category.to_s}/" # for internal use only
            end
          end

          def self.path_name(traced_obj, options = {})
            return options[:path] if options[:path]

            class_name = class_name(traced_obj, options)
            if options[:name]
              if class_name
                "#{class_name}/#{options[:name]}"
              else
                options[:name]
              end
            elsif traced_obj.respond_to?(:newrelic_metric_path)
              traced_obj.newrelic_metric_path
            else
              class_name
            end
          end

          def self.class_name(traced_obj, options = {})
            return options[:class_name] if options[:class_name]

            if traced_obj.is_a?(Class) || traced_obj.is_a?(Module)
              traced_obj.name
            else
              traced_obj.class.name
            end
          end
        end

        # Yield to the given block with NewRelic tracing.  Used by
        # default instrumentation on controller actions in Rails.
        # But it can also be used in custom instrumentation of controller
        # methods and background tasks.
        #
        # This is the method invoked by instrumentation added by the
        # <tt>ClassMethods#add_transaction_tracer</tt>.
        #
        # Here's a more verbose version of the example shown in
        # <tt>ClassMethods#add_transaction_tracer</tt> using this method instead of
        # #add_transaction_tracer.
        #
        # Below is a controller with an +invoke_operation+ action which
        # dispatches to more specific operation methods based on a
        # parameter (very dangerous, btw!).  With this instrumentation,
        # the +invoke_operation+ action is ignored but the operation
        # methods show up in New Relic as if they were first class controller
        # actions
        #
        #   MyController < ActionController::Base
        #     include NewRelic::Agent::Instrumentation::ControllerInstrumentation
        #     # dispatch the given op to the method given by the service parameter.
        #     def invoke_operation
        #       op = params['operation']
        #       perform_action_with_newrelic_trace(:name => op) do
        #         send op, params['message']
        #       end
        #     end
        #     # Ignore the invoker to avoid double counting
        #     newrelic_ignore :only => 'invoke_operation'
        #   end
        #
        #
        # When invoking this method explicitly as in the example above, pass in a
        # block to measure with some combination of options:
        #
        # * <tt>:category => :controller</tt> indicates that this is a
        #   controller action and will appear with all the other actions.  This
        #   is the default.
        # * <tt>:category => :task</tt> indicates that this is a
        #   background task and will show up in New Relic with other background
        #   tasks instead of in the controllers list
        # * <tt>:category => :middleware</tt> if you are instrumenting a rack
        #   middleware call.  The <tt>:name</tt> is optional, useful if you
        #   have more than one potential transaction in the #call.
        # * <tt>:category => :uri</tt> indicates that this is a
        #   web transaction whose name is a normalized URI, where  'normalized'
        #   means the URI does not have any elements with data in them such
        #   as in many REST URIs.
        # * <tt>:name => action_name</tt> is used to specify the action
        #   name used as part of the metric name
        # * <tt>:params => {...}</tt> to provide information about the context
        #   of the call, used in transaction trace display, for example:
        #   <tt>:params => { :account => @account.name, :file => file.name }</tt>
        #   These are treated similarly to request parameters in web transactions.
        #
        # Seldomly used options:
        #
        # * <tt>:class_name => Class.name</tt> is used to override the name
        #   of the class when used inside the metric name.  Default is the
        #   current class.
        # * <tt>:path => metric_path</tt> is *deprecated* in the public API.  It
        #   allows you to set the entire metric after the category part.  Overrides
        #   all the other options.
        # * <tt>:request => Rack::Request#new(env)</tt> is used to pass in a
        #   request object that may respond to path and referer.
        #
        # @api public
        #
        def perform_action_with_newrelic_trace(*args, &block) # THREAD_LOCAL_ACCESS
          NewRelic::Agent.record_api_supportability_metric(:perform_action_with_newrelic_trace)
          state = NewRelic::Agent::Tracer.state
          request = newrelic_request(args)
          queue_start_time = detect_queue_start_time(request)

          skip_tracing = do_not_trace? || !state.is_execution_traced?

          if skip_tracing
            state.current_transaction&.ignore!
            NewRelic::Agent.disable_all_tracing { return yield }
          end

          # This method has traditionally taken a variable number of arguments, but the
          # only one that is expected / used is a single options hash.  We are preserving
          # the *args method signature to ensure backwards compatibility.

          trace_options = args.last.is_a?(Hash) ? args.last : NR_DEFAULT_OPTIONS
          category = trace_options[:category] || :controller
          txn_options = create_transaction_options(trace_options, category, state, queue_start_time)

          begin
            finishable = Tracer.start_transaction_or_segment(
              name: txn_options[:transaction_name],
              category: category,
              options: txn_options
            )

            begin
              yield
            rescue => e
              NewRelic::Agent.notice_error(e)
              raise
            end
          ensure
            # the following line needs else branch coverage
            finishable.finish if finishable # rubocop:disable Style/SafeNavigation
          end
        end

        protected

        def newrelic_request(args)
          opts = args.first
          # passed as a parameter to add_transaction_tracer
          if opts.respond_to?(:keys) && opts.respond_to?(:[]) && opts[:request]
            opts[:request]
          # in a Rails app
          elsif self.respond_to?(:request)
            self.request rescue nil
          end
        end

        # Should be implemented in the dispatcher class
        def newrelic_response_code; end

        def newrelic_request_headers(request)
          if request
            if request.respond_to?(:headers)
              request.headers
            elsif request.respond_to?(:env)
              request.env
            end
          end
        end

        # overridable method to determine whether to trace an action
        # or not - you may override this in your controller and supply
        # your own logic for ignoring transactions.
        def do_not_trace?
          _is_filtered?(NR_DO_NOT_TRACE_KEY)
        end

        # overridable method to determine whether to trace an action
        # for purposes of apdex measurement - you can use this to
        # ignore things like api calls or other fast non-user-facing
        # actions
        def ignore_apdex?
          _is_filtered?(NR_IGNORE_APDEX_KEY)
        end

        def ignore_enduser?
          _is_filtered?(NR_IGNORE_ENDUSER_KEY)
        end

        private

        def create_transaction_options(trace_options, category, state, queue_start_time)
          txn_options = {}
          txn_options[:request] = trace_options[:request]
          txn_options[:request] ||= request if respond_to?(:request) rescue nil
          # params should have been filtered before calling perform_action_with_newrelic_trace
          txn_options[:filtered_params] = trace_options[:params]
          txn_options[:transaction_name] = TransactionNamer.name_for(nil, self, category, trace_options)
          txn_options[:apdex_start_time] = queue_start_time
          txn_options[:ignore_apdex] = ignore_apdex?
          txn_options[:ignore_enduser] = ignore_enduser?
          NewRelic::Agent::MethodTracerHelpers::SOURCE_CODE_INFORMATION_PARAMETERS.each do |parameter|
            txn_options[parameter] = trace_options[parameter]
          end
          txn_options
        end

        # Filter out a request if it matches one of our parameters for
        # ignoring it - the key is either NR_DO_NOT_TRACE_KEY or NR_IGNORE_APDEX_KEY
        def _is_filtered?(key)
          name = if respond_to?(:action_name)
            action_name
          else
            :'[action_name_missing]'
          end

          NewRelic::Agent::Instrumentation::IgnoreActions.is_filtered?(
            key,
            self.class,
            name
          )
        end

        def detect_queue_start_time(request)
          headers = newrelic_request_headers(request)

          QueueTime.parse_frontend_timestamp(headers) if headers
        end
      end
    end
  end
end
