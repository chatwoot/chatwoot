# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/method_tracer'
require 'new_relic/agent/transaction'
require 'new_relic/agent/tracer'
require 'new_relic/agent/instrumentation/queue_time'
require 'new_relic/agent/instrumentation/controller_instrumentation'
require 'new_relic/agent/instrumentation/middleware_tracing'

module NewRelic
  module Agent
    module Instrumentation
      class MiddlewareProxy
        include MiddlewareTracing

        ANONYMOUS_CLASS = 'AnonymousClass'.freeze
        OBJECT_CLASS_NAME = 'Object'.freeze

        # This class is used to wrap classes that are passed to
        # Rack::Builder#use without synchronously instantiating those classes.
        # A MiddlewareProxy::Generator responds to new, like a Class would, and
        # passes through arguments to new to the original target class.
        class Generator
          def initialize(middleware_class)
            @middleware_class = middleware_class
          end

          def new(*args, &blk)
            middleware_instance = @middleware_class.new(*args, &blk)
            MiddlewareProxy.wrap(middleware_instance)
          end

          ruby2_keywords(:new) if respond_to?(:ruby2_keywords, true)
        end

        def self.is_sinatra_app?(target)
          defined?(::Sinatra::Base) && target.kind_of?(::Sinatra::Base)
        end

        def self.for_class(target_class)
          Generator.new(target_class)
        end

        def self.needs_wrapping?(target)
          (
            !target.respond_to?(:_nr_has_middleware_tracing) &&
            !is_sinatra_app?(target)
          )
        end

        def self.wrap(target, is_app = false)
          if needs_wrapping?(target)
            self.new(target, is_app)
          else
            target
          end
        end

        attr_reader :target, :category, :transaction_options

        def initialize(target, is_app = false)
          @target = target
          @is_app = is_app
          @category = determine_category
          @target_class_name = determine_class_name
          @transaction_name = "#{determine_prefix}#{@target_class_name}/call"
          @transaction_options = {
            :transaction_name => @transaction_name
          }
        end

        def determine_category
          if @is_app
            :rack
          else
            :middleware
          end
        end

        def determine_prefix
          ControllerInstrumentation::TransactionNamer.prefix_for_category(nil, @category)
        end

        # In 'normal' usage, the target will be an application instance that
        # responds to #call. With Rails, however, the target may be a subclass
        # of Rails::Application that defines a method_missing that proxies #call
        # to a singleton instance of the subclass. We need to ensure that we
        # capture the correct name in both cases.
        def determine_class_name
          clazz = class_for_target

          name = clazz.name
          name = clazz.superclass.name if name.nil? || name == ''
          name = ANONYMOUS_CLASS if name.nil? || name == OBJECT_CLASS_NAME
          name
        end

        def class_for_target
          if @target.is_a?(Class)
            @target
          else
            @target.class
          end
        end
      end
    end
  end
end
