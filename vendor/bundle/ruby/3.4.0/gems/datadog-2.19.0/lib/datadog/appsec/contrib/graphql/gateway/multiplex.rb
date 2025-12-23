# frozen_string_literal: true

require 'graphql'

require_relative '../../../instrumentation/gateway/argument'

module Datadog
  module AppSec
    module Contrib
      module GraphQL
        module Gateway
          # Gateway Request argument. Normalized extration of data from Rack::Request
          class Multiplex < Instrumentation::Gateway::Argument
            attr_reader :multiplex

            def initialize(multiplex)
              super()
              @multiplex = multiplex
            end

            def arguments
              @arguments ||= build_arguments_hash
            end

            def queries
              @multiplex.queries
            end

            private

            # This method builds an array of argument hashes for each field with arguments in the query.
            #
            # For example, given the following query:
            # query ($postSlug: ID = "my-first-post", $withComments: Boolean!) {
            #   firstPost: post(slug: $postSlug) {
            #     title
            #     comments @include(if: $withComments) {
            #       author { name }
            #       content
            #     }
            #   }
            # }
            #
            # The result would be:
            # {"post"=>[{"slug"=>"my-first-post"}], "comments"=>[{"include"=>{"if"=>true}}]}
            #
            # Note that the `comments` "include" directive is included in the arguments list
            def build_arguments_hash
              queries.each_with_object({}) do |query, args_hash|
                next unless query.selected_operation

                arguments_from_selections(query.selected_operation.selections, query.variables, args_hash)
              end
            end

            def arguments_from_selections(selections, query_variables, args_hash)
              selections.each do |selection|
                # rubocop:disable Style/ClassEqualityComparison
                next unless selection.class.name == Integration::AST_NODE_CLASS_NAMES[:field]
                # rubocop:enable Style/ClassEqualityComparison

                selection_name = selection.alias || selection.name

                if !selection.arguments.empty? || !selection.directives.empty?
                  args_hash[selection_name] ||= []
                  args_hash[selection_name] <<
                    arguments_hash(selection.arguments, query_variables).merge!(
                      arguments_from_directives(selection.directives, query_variables)
                    )
                end

                arguments_from_selections(selection.selections, query_variables, args_hash)
              end
            end

            def arguments_from_directives(directives, query_variables)
              directives.each_with_object({}) do |directive, args_hash|
                # rubocop:disable Style/ClassEqualityComparison
                next unless directive.class.name == Integration::AST_NODE_CLASS_NAMES[:directive]
                # rubocop:enable Style/ClassEqualityComparison

                args_hash[directive.name] = arguments_hash(directive.arguments, query_variables)
              end
            end

            def arguments_hash(arguments, query_variables)
              arguments.each_with_object({}) do |argument, args_hash|
                args_hash[argument.name] = argument_value(argument, query_variables)
              end
            end

            def argument_value(argument, query_variables)
              case argument.value.class.name
              when Integration::AST_NODE_CLASS_NAMES[:variable_identifier]
                # we need to pass query.variables here instead of query.provided_variables,
                # since #provided_variables don't know anything about variable default value
                query_variables[argument.value.name]
              when Integration::AST_NODE_CLASS_NAMES[:input_object]
                arguments_hash(argument.value.arguments, query_variables)
              else
                argument.value
              end
            end
          end
        end
      end
    end
  end
end
