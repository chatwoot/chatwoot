# frozen_string_literal: true

require "ripper"

module AnnotateRb
  module ModelAnnotator
    module FileParser
      class CustomParser < Ripper
        # Overview of Ripper: https://kddnewton.com/2022/02/14/formatting-ruby-part-1.html
        # Ripper API: https://kddnewton.com/ripper-docs/

        class << self
          def parse(string)
            _parser = new(string, "", 0).tap(&:parse)
          end
        end

        attr_reader :comments

        def initialize(input, ...)
          super
          @_stack_code_block = []
          @_input = input
          @_const_event_map = {}

          @comments = []
          @block_starts = []
          @block_ends = []
          @const_type_map = {}
        end

        def starts
          @block_starts
        end

        def ends
          @block_ends
        end

        def type_map
          @const_type_map
        end

        def on_program(...)
          {
            comments: @comments,
            starts: @block_starts,
            ends: @block_ends,
            type_map: @const_type_map
          }
        end

        def on_const_ref(const)
          add_event(__method__, const, lineno)
          @block_starts << [const, lineno]
          super
        end

        # Used for `class Foo::User`
        def on_const_path_ref(_left, const)
          add_event(__method__, const, lineno)
          @block_starts << [const, lineno]
          super
        end

        def on_module(const, _bodystmt)
          add_event(__method__, const, lineno)
          @const_type_map[const] = :module unless @const_type_map[const]
          @block_ends << [const, lineno]
          super
        end

        def on_class(const, _superclass, _bodystmt)
          add_event(__method__, const, lineno)
          @const_type_map[const] = :class unless @const_type_map[const]
          @block_ends << [const, lineno]
          super
        end

        # Gets the `RSpec` opening in:
        # ```ruby
        # RSpec.describe "Collapsed::TestModel" do
        #   # Deliberately left empty
        # end
        # ```
        # receiver: "RSpec", operator: ".", method: "describe"
        def on_command_call(receiver, operator, method, args)
          add_event(__method__, receiver, lineno)
          @block_starts << [receiver, lineno]

          # We keep track of blocks using a stack
          @_stack_code_block << receiver
          super
        end

        def on_method_add_block(method, block)
          # When parsing a line with no explicit receiver, the method will be presented in an Array.
          # It's not immediately clear why.
          #
          # Example:
          # ```ruby
          # describe "Collapsed::TestModel" do
          #   # Deliberately left empty
          # end
          # ```
          #
          # => method = ["describe"]
          if method.is_a?(Array) && method.size == 1
            method = method.first
          end

          add_event(__method__, method, lineno)

          if @_stack_code_block.last == method
            @block_ends << [method, lineno]
            @_stack_code_block.pop
          else
            @block_starts << [method, lineno]
          end
          super
        end

        def on_method_add_arg(method, args)
          add_event(__method__, method, lineno)
          @block_starts << [method, lineno]

          # We keep track of blocks using a stack
          @_stack_code_block << method
          super
        end

        # Gets the `FactoryBot` line in:
        # ```ruby
        # FactoryBot.define do
        #   factory :user do
        #     ...
        #   end
        # end
        # ```
        def on_call(receiver, operator, message)
          # We only want to add the parsed line if the beginning of the Ruby
          if @block_starts.empty?
            add_event(__method__, receiver, lineno)
            @block_starts << [receiver, lineno]
          end

          super
        end

        # Gets the `factory` block start in:
        # ```ruby
        # factory :user, aliases: [:author, :commenter] do
        #   ...
        # end
        # ```
        def on_command(message, args)
          add_event(__method__, message, lineno)
          @block_starts << [message, lineno]

          # We keep track of blocks using a stack
          @_stack_code_block << message
          super
        end

        # Matches the `end` in:
        # ```ruby
        # factory :user, aliases: [:author, :commenter] do
        #   first_name { "John" }
        #   last_name { "Doe" }
        #   date_of_birth { 18.years.ago }
        # end
        # ```
        def on_do_block(block_var, bodystmt)
          if block_var.blank? && bodystmt.blank?
            @block_ends << ["end", lineno]
            add_event(__method__, "end", lineno)
          end
          super
        end

        def on_embdoc_beg(value)
          add_event(__method__, value, lineno)
          @comments << [value.strip, lineno]
          super
        end

        def on_embdoc_end(value)
          add_event(__method__, value, lineno)
          @comments << [value.strip, lineno]
          super
        end

        def on_embdoc(value)
          add_event(__method__, value, lineno)
          @comments << [value.strip, lineno]
          super
        end

        def on_comment(value)
          add_event(__method__, value, lineno)
          @comments << [value.strip, lineno]
          super
        end

        private

        def add_event(event, const, lineno)
          if !@_const_event_map[lineno]
            @_const_event_map[lineno] = []
          end

          @_const_event_map[lineno] << [const, event]
        end
      end
    end
  end
end
