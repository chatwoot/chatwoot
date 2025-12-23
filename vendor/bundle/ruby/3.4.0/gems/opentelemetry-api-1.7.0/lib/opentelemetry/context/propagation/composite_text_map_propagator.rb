# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  class Context
    module Propagation
      # A composite text map propagator either composes a list of injectors and a
      # list of extractors, or wraps a list of propagators, into a single interface
      # exposing inject and extract methods. Injection and extraction will preserve
      # the order of the injectors and extractors (or propagators) passed in during
      # initialization.
      class CompositeTextMapPropagator
        class << self
          private :new

          # Returns a Propagator that extracts using the provided extractors
          # and injectors.
          #
          # @param [Array<#inject, #fields>] injectors An array of text map injectors
          # @param [Array<#extract>] extractors An array of text map extractors
          def compose(injectors:, extractors:)
            raise ArgumentError, 'injectors and extractors must both be non-nil arrays' unless injectors.is_a?(Array) && extractors.is_a?(Array)

            new(injectors: injectors, extractors: extractors)
          end

          # Returns a Propagator that extracts using the provided propagators.
          #
          # @param [Array<#inject, #extract, #fields>] propagators An array of
          #   text map propagators
          def compose_propagators(propagators)
            raise ArgumentError, 'propagators must be a non-nil array' unless propagators.is_a?(Array)
            return NoopTextMapPropagator.new if propagators.empty?
            return propagators.first if propagators.size == 1

            new(propagators: propagators)
          end
        end

        # @api private
        def initialize(injectors: nil, extractors: nil, propagators: nil)
          @injectors = injectors
          @extractors = extractors
          @propagators = propagators
        end

        # Runs injectors or propagators in order. If an injection fails
        # a warning will be logged and remaining injectors will be executed.
        #
        # @param [Object] carrier A mutable carrier to inject context into.
        # @param [optional Context] context Context to be injected into carrier. Defaults
        #   to +Context.current+.
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   setter will be used.
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
          injectors = @injectors || @propagators
          injectors.each do |injector|
            injector.inject(carrier, context: context, setter: setter)
          rescue StandardError => e
            OpenTelemetry.logger.warn "Error in CompositePropagator#inject #{e.message}"
          end
          nil
        end

        # Runs extractors or propagators in order and returns a Context updated
        # with the results of each extraction. If an extraction fails, a warning
        # will be logged and remaining extractors will continue to be executed. Always
        # returns a valid context.
        #
        # @param [Object] carrier The carrier to extract context from.
        # @param [optional Context] context Context to be updated with the state
        #   extracted from the carrier. Defaults to +Context.current+.
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   getter will be used.
        #
        # @return [Context] a new context updated with state extracted from the
        #   carrier
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          extractors = @extractors || @propagators
          extractors.inject(context) do |ctx, extractor|
            extractor.extract(carrier, context: ctx, getter: getter)
          rescue StandardError => e
            OpenTelemetry.logger.warn "Error in CompositePropagator#extract #{e.message}"
            ctx
          end
        end

        # Returns the union of the propagation fields returned by the composed injectors
        # or propagators. If your carrier is reused, you should delete the fields returned
        # by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          injectors = @injectors || @propagators
          injectors.flat_map(&:fields).uniq
        end
      end
    end
  end
end
