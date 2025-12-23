# frozen_string_literal: true

require "sentry/breadcrumb_buffer"
require "sentry/propagation_context"
require "sentry/attachment"
require "etc"

module Sentry
  class Scope
    include ArgumentCheckingHelper

    ATTRIBUTES = [
      :transaction_name,
      :transaction_source,
      :contexts,
      :extra,
      :tags,
      :user,
      :level,
      :breadcrumbs,
      :fingerprint,
      :event_processors,
      :rack_env,
      :span,
      :session,
      :attachments,
      :propagation_context
    ]

    attr_reader(*ATTRIBUTES)

    # @param max_breadcrumbs [Integer] the maximum number of breadcrumbs to be stored in the scope.
    def initialize(max_breadcrumbs: nil)
      @max_breadcrumbs = max_breadcrumbs
      set_default_value
    end

    # Resets the scope's attributes to defaults.
    # @return [void]
    def clear
      set_default_value
    end

    # Applies stored attributes and event processors to the given event.
    # @param event [Event]
    # @param hint [Hash] the hint data that'll be passed to event processors.
    # @return [Event]
    def apply_to_event(event, hint = nil)
      unless event.is_a?(CheckInEvent)
        event.tags = tags.merge(event.tags)
        event.user = user.merge(event.user)
        event.extra = extra.merge(event.extra)
        event.contexts = contexts.merge(event.contexts)
        event.transaction = transaction_name if transaction_name
        event.transaction_info = { source: transaction_source } if transaction_source
        event.fingerprint = fingerprint
        event.level = level
        event.breadcrumbs = breadcrumbs
        event.rack_env = rack_env if rack_env
        event.attachments = attachments
      end

      if span
        event.contexts[:trace] ||= span.get_trace_context
      else
        event.contexts[:trace] ||= propagation_context.get_trace_context
        event.dynamic_sampling_context ||= propagation_context.get_dynamic_sampling_context
      end

      all_event_processors = self.class.global_event_processors + @event_processors

      unless all_event_processors.empty?
        all_event_processors.each do |processor_block|
          event = processor_block.call(event, hint)
        end
      end

      event
    end

    # Adds the breadcrumb to the scope's breadcrumbs buffer.
    # @param breadcrumb [Breadcrumb]
    # @return [void]
    def add_breadcrumb(breadcrumb)
      breadcrumbs.record(breadcrumb)
    end

    # Clears the scope's breadcrumbs buffer
    # @return [void]
    def clear_breadcrumbs
      set_new_breadcrumb_buffer
    end

    # @return [Scope]
    def dup
      copy = super
      copy.breadcrumbs = breadcrumbs.dup
      copy.contexts = contexts.deep_dup
      copy.extra = extra.deep_dup
      copy.tags = tags.deep_dup
      copy.user = user.deep_dup
      copy.transaction_name = transaction_name.dup
      copy.transaction_source = transaction_source.dup
      copy.fingerprint = fingerprint.deep_dup
      copy.span = span.deep_dup
      copy.session = session.deep_dup
      copy.propagation_context = propagation_context.deep_dup
      copy.attachments = attachments.dup
      copy
    end

    # Updates the scope's data from a given scope.
    # @param scope [Scope]
    # @return [void]
    def update_from_scope(scope)
      self.breadcrumbs = scope.breadcrumbs
      self.contexts = scope.contexts
      self.extra = scope.extra
      self.tags = scope.tags
      self.user = scope.user
      self.transaction_name = scope.transaction_name
      self.transaction_source = scope.transaction_source
      self.fingerprint = scope.fingerprint
      self.span = scope.span
      self.propagation_context = scope.propagation_context
      self.attachments = scope.attachments
    end

    # Updates the scope's data from the given options.
    # @param contexts [Hash]
    # @param extras [Hash]
    # @param tags [Hash]
    # @param user [Hash]
    # @param level [String, Symbol]
    # @param fingerprint [Array]
    # @param attachments [Array<Attachment>]
    # @return [Array]
    def update_from_options(
      contexts: nil,
      extra: nil,
      tags: nil,
      user: nil,
      level: nil,
      fingerprint: nil,
      attachments: nil,
      **options
    )
      self.contexts.merge!(contexts) if contexts
      self.extra.merge!(extra) if extra
      self.tags.merge!(tags) if tags
      self.user = user if user
      self.level = level if level
      self.fingerprint = fingerprint if fingerprint

      # Returns unsupported option keys so we can notify users.
      options.keys
    end

    # Sets the scope's rack_env attribute.
    # @param env [Hash]
    # @return [Hash]
    def set_rack_env(env)
      env = env || {}
      @rack_env = env
    end

    # Sets the scope's span attribute.
    # @param span [Span]
    # @return [Span]
    def set_span(span)
      check_argument_type!(span, Span)
      @span = span
    end

    # @!macro set_user
    def set_user(user_hash)
      check_argument_type!(user_hash, Hash)
      @user = user_hash
    end

    # @!macro set_extras
    def set_extras(extras_hash)
      check_argument_type!(extras_hash, Hash)
      @extra.merge!(extras_hash)
    end

    # Adds a new key-value pair to current extras.
    # @param key [String, Symbol]
    # @param value [Object]
    # @return [Hash]
    def set_extra(key, value)
      set_extras(key => value)
    end

    # @!macro set_tags
    def set_tags(tags_hash)
      check_argument_type!(tags_hash, Hash)
      @tags.merge!(tags_hash)
    end

    # Adds a new key-value pair to current tags.
    # @param key [String, Symbol]
    # @param value [Object]
    # @return [Hash]
    def set_tag(key, value)
      set_tags(key => value)
    end

    # Updates the scope's contexts attribute by merging with the old value.
    # @param contexts [Hash]
    # @return [Hash]
    def set_contexts(contexts_hash)
      check_argument_type!(contexts_hash, Hash)
      contexts_hash.values.each do |val|
        check_argument_type!(val, Hash)
      end

      @contexts.merge!(contexts_hash) do |key, old, new|
        old.merge(new)
      end
    end

    # @!macro set_context
    def set_context(key, value)
      check_argument_type!(value, Hash)
      set_contexts(key => value)
    end

    # Sets the scope's level attribute.
    # @param level [String, Symbol]
    # @return [void]
    def set_level(level)
      @level = level
    end

    # Appends a new transaction name to the scope.
    # The "transaction" here does not refer to `Transaction` objects.
    # @param transaction_name [String]
    # @return [void]
    def set_transaction_name(transaction_name, source: :custom)
      @transaction_name = transaction_name
      @transaction_source = source
    end

    # Sets the currently active session on the scope.
    # @param session [Session, nil]
    # @return [void]
    def set_session(session)
      @session = session
    end

    # These are high cardinality and thus bad.
    # @return [Boolean]
    def transaction_source_low_quality?
      transaction_source == :url
    end

    # Returns the associated Transaction object.
    # @return [Transaction, nil]
    def get_transaction
      span.transaction if span
    end

    # Returns the associated Span object.
    # @return [Span, nil]
    def get_span
      span
    end

    # Sets the scope's fingerprint attribute.
    # @param fingerprint [Array]
    # @return [Array]
    def set_fingerprint(fingerprint)
      check_argument_type!(fingerprint, Array)

      @fingerprint = fingerprint
    end

    # Adds a new event processor [Proc] to the scope.
    # @param block [Proc]
    # @return [void]
    def add_event_processor(&block)
      @event_processors << block
    end

    # Generate a new propagation context either from the incoming env headers or from scratch.
    # @param env [Hash, nil]
    # @return [void]
    def generate_propagation_context(env = nil)
      @propagation_context = PropagationContext.new(self, env)
    end

    # Add a new attachment to the scope.
    def add_attachment(**opts)
      attachments << (attachment = Attachment.new(**opts))
      attachment
    end

    protected

    # for duplicating scopes internally
    attr_writer(*ATTRIBUTES)

    private

    def set_default_value
      @contexts = { os: self.class.os_context, runtime: self.class.runtime_context }
      @extra = {}
      @tags = {}
      @user = {}
      @level = :error
      @fingerprint = []
      @transaction_name = nil
      @transaction_source = nil
      @event_processors = []
      @rack_env = {}
      @span = nil
      @session = nil
      @attachments = []
      generate_propagation_context
      set_new_breadcrumb_buffer
    end

    def set_new_breadcrumb_buffer
      @breadcrumbs = BreadcrumbBuffer.new(@max_breadcrumbs)
    end

    class << self
      # @return [Hash]
      def os_context
        @os_context ||=
          begin
            uname = Etc.uname
            {
              name: uname[:sysname] || RbConfig::CONFIG["host_os"],
              version: uname[:version],
              build: uname[:release],
              kernel_version: uname[:version],
              machine: uname[:machine]
            }
          end
      end

      # @return [Hash]
      def runtime_context
        @runtime_context ||= {
          name: RbConfig::CONFIG["ruby_install_name"],
          version: RUBY_DESCRIPTION || Sentry.sys_command("ruby -v")
        }
      end

      # Returns the global event processors array.
      # @return [Array<Proc>]
      def global_event_processors
        @global_event_processors ||= []
      end

      # Adds a new global event processor [Proc].
      # Sometimes we need a global event processor without needing to configure scope.
      # These run before scope event processors.
      #
      # @param block [Proc]
      # @return [void]
      def add_global_event_processor(&block)
        global_event_processors << block
      end
    end
  end
end
