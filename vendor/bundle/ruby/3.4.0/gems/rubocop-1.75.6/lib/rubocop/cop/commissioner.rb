# frozen_string_literal: true

module RuboCop
  module Cop
    # Commissioner class is responsible for processing the AST and delegating
    # work to the specified cops.
    class Commissioner
      include RuboCop::AST::Traversal

      RESTRICTED_CALLBACKS = %i[on_send on_csend after_send after_csend].freeze
      private_constant :RESTRICTED_CALLBACKS

      # How a Commissioner returns the results of the investigation
      # as a list of Cop::InvestigationReport and any errors caught
      # during the investigation.
      # Immutable
      # Consider creation API private
      InvestigationReport = Struct.new(:processed_source, :cop_reports, :errors) do
        def cops
          @cops ||= cop_reports.map(&:cop)
        end

        def offenses_per_cop
          @offenses_per_cop ||= cop_reports.map(&:offenses)
        end

        def correctors
          @correctors ||= cop_reports.map(&:corrector)
        end

        def offenses
          @offenses ||= offenses_per_cop.flatten(1)
        end

        def merge(investigation)
          InvestigationReport.new(processed_source,
                                  cop_reports + investigation.cop_reports,
                                  errors + investigation.errors)
        end
      end

      attr_reader :errors

      def initialize(cops, forces = [], options = {})
        @cops = cops
        @forces = forces
        @options = options
        initialize_callbacks

        reset
      end

      # Create methods like :on_send, :on_super, etc. They will be called
      # during AST traversal and try to call corresponding methods on cops.
      # A call to `super` is used
      # to continue iterating over the children of a node.
      # However, if we know that a certain node type (like `int`) never has
      # child nodes, there is no reason to pay the cost of calling `super`.
      Parser::Meta::NODE_TYPES.each do |node_type|
        method_name = :"on_#{node_type}"
        next unless method_defined?(method_name)

        # Hacky: Comment-out code as needed
        r = '#' unless RESTRICTED_CALLBACKS.include?(method_name) # has Restricted?
        c = '#' if NO_CHILD_NODES.include?(node_type) # has Children?

        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
                  def on_#{node_type}(node)                               # def on_send(node)
                    trigger_responding_cops(:on_#{node_type}, node)       #   trigger_responding_cops(:on_send, node)
              #{r}  trigger_restricted_cops(:on_#{node_type}, node)       #   trigger_restricted_cops(:on_send, node)
          #{c}      super(node)                                           #   super(node)
          #{c}      trigger_responding_cops(:after_#{node_type}, node)    #   trigger_responding_cops(:after_send, node)
          #{c}#{r}  trigger_restricted_cops(:after_#{node_type}, node)    #   trigger_restricted_cops(:after_send, node)
                  end                                                     # end
        RUBY
      end

      # @return [InvestigationReport]
      def investigate(processed_source, offset: 0, original: processed_source)
        reset

        begin_investigation(processed_source, offset: offset, original: original)
        if processed_source.valid_syntax?
          invoke(:on_new_investigation, @cops)
          invoke_with_argument(:investigate, @forces, processed_source)

          walk(processed_source.ast) unless @cops.empty?
          invoke(:on_investigation_end, @cops)
        else
          invoke(:on_other_file, @cops)
        end
        reports = @cops.map { |cop| cop.send(:complete_investigation) }
        InvestigationReport.new(processed_source, reports, @errors)
      end

      private

      def begin_investigation(processed_source, offset:, original:)
        @cops.each do |cop|
          cop.begin_investigation(processed_source, offset: offset, original: original)
        end
      end

      def trigger_responding_cops(callback, node)
        @callbacks[callback]&.each do |cop|
          with_cop_error_handling(cop, node) do
            cop.public_send(callback, node)
          end
        end
      end

      def reset
        @errors = []
      end

      def initialize_callbacks
        @callbacks = build_callbacks(@cops)
        @restricted_map = restrict_callbacks(@callbacks)
      end

      def build_callbacks(cops)
        callbacks = {}
        cops.each do |cop|
          cop.callbacks_needed.each do |callback|
            (callbacks[callback] ||= []) << cop
          end
        end
        callbacks
      end

      def restrict_callbacks(callbacks)
        restricted = {}
        RESTRICTED_CALLBACKS.each do |callback|
          restricted[callback] = restricted_map(callbacks[callback])
        end
        restricted
      end

      def trigger_restricted_cops(event, node)
        name = node.method_name
        @restricted_map[event][name]&.each do |cop|
          with_cop_error_handling(cop, node) do
            cop.public_send(event, node)
          end
        end
      end

      # NOTE: mutates `callbacks` in place
      def restricted_map(callbacks)
        map = {}
        callbacks&.select! do |cop|
          restrictions = cop.class.send :restrict_on_send
          restrictions.each { |name| (map[name] ||= []) << cop }
          restrictions.empty?
        end
        map
      end

      def invoke(callback, cops)
        cops.each { |cop| with_cop_error_handling(cop) { cop.send(callback) } }
      end

      def invoke_with_argument(callback, cops, arg)
        cops.each { |cop| with_cop_error_handling(cop) { cop.send(callback, arg) } }
      end

      # Allow blind rescues here, since we're absorbing and packaging or
      # re-raising exceptions that can be raised from within the individual
      # cops' `#investigate` methods.
      def with_cop_error_handling(cop, node = nil)
        yield
      rescue StandardError => e
        raise e if @options[:raise_error] # For internal testing

        err = ErrorWithAnalyzedFileLocation.new(cause: e, node: node, cop: cop)
        raise err if @options[:raise_cop_error] # From user-input option

        @errors << err
      end
    end
  end
end
