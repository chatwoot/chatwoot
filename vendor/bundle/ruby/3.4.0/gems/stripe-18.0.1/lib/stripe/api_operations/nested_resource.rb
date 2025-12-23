# frozen_string_literal: true

module Stripe
  module APIOperations
    # Adds methods to help manipulate a subresource from its parent resource so
    # that it's possible to do so from a static context (i.e. without a
    # pre-existing collection of subresources on the parent).
    #
    # For example, a transfer gains the static methods for reversals so that the
    # methods `.create_reversal`, `.retrieve_reversal`, `.update_reversal`,
    # etc. all become available.
    module NestedResource
      def nested_resource_class_methods(resource, path: nil, operations: nil,
                                        resource_plural: nil)
        resource_plural ||= "#{resource}s"
        path ||= resource_plural

        raise ArgumentError, "operations array required" if operations.nil?

        resource_url_method = :"#{resource}s_url"

        define_singleton_method(resource_url_method) do |id, nested_id = nil|
          url = "#{resource_url}/#{CGI.escape(id)}/#{CGI.escape(path)}"
          url += "/#{CGI.escape(nested_id)}" unless nested_id.nil?
          url
        end

        operations.each do |operation|
          define_operation(
            resource,
            operation,
            resource_url_method,
            resource_plural
          )
        end
      end

      private def define_operation(
        resource,
        operation,
        resource_url_method,
        resource_plural
      )
        case operation
        when :create
          define_singleton_method(:"create_#{resource}") \
              do |id, params = {}, opts = {}|
                request_stripe_object(
                  method: :post,
                  path: send(resource_url_method, id),
                  params: params,
                  opts: opts
                )
              end
        when :retrieve
          define_singleton_method(:"retrieve_#{resource}") \
              do |id, nested_id, params = {}, opts = {}|
                request_stripe_object(
                  method: :get,
                  path: send(resource_url_method, id, nested_id),
                  params: params,
                  opts: opts
                )
              end
        when :update
          define_singleton_method(:"update_#{resource}") \
              do |id, nested_id, params = {}, opts = {}|
                request_stripe_object(
                  method: :post,
                  path: send(resource_url_method, id, nested_id),
                  params: params,
                  opts: opts
                )
              end
        when :delete
          define_singleton_method(:"delete_#{resource}") \
              do |id, nested_id, params = {}, opts = {}|
                request_stripe_object(
                  method: :delete,
                  path: send(resource_url_method, id, nested_id),
                  params: params,
                  opts: opts
                )
              end
        when :list
          define_singleton_method(:"list_#{resource_plural}") \
              do |id, params = {}, opts = {}|
                request_stripe_object(
                  method: :get,
                  path: send(resource_url_method, id),
                  params: params,
                  opts: opts
                )
              end
        else
          raise ArgumentError, "Unknown operation: #{operation.inspect}"
        end
      end
    end
  end
end
