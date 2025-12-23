# frozen_string_literal: true

module Stripe
  module APIOperations
    module Save
      module ClassMethods
        # Updates an API resource
        #
        # Updates the identified resource with the passed in parameters.
        #
        # ==== Attributes
        #
        # * +id+ - ID of the resource to update.
        # * +params+ - A hash of parameters to pass to the API
        # * +opts+ - A Hash of additional options (separate from the params /
        #   object values) to be added to the request. E.g. to allow for an
        #   idempotency_key to be passed in the request headers, or for the
        #   api_key to be overwritten. See
        #   {APIOperations::Request.execute_resource_request}.
        def update(id, params = {}, opts = {})
          params.each_key do |k|
            raise ArgumentError, "Cannot update protected field: #{k}" if protected_fields.include?(k)
          end

          request_stripe_object(
            method: :post,
            path: "#{resource_url}/#{id}",
            params: params,
            opts: opts
          )
        end
      end

      # The `save` method is DEPRECATED and will be removed in a future major
      # version of the library. Use the `update` method on the resource instead.
      #
      # Creates or updates an API resource.
      #
      # If the resource doesn't yet have an assigned ID and the resource is one
      # that can be created, then the method attempts to create the resource.
      # The resource is updated otherwise.
      #
      # ==== Attributes
      #
      # * +params+ - Overrides any parameters in the resource's serialized data
      #   and includes them in the create or update. If +:req_url:+ is included
      #   in the list, it overrides the update URL used for the create or
      #   update.
      # * +opts+ - A Hash of additional options (separate from the params /
      #   object values) to be added to the request. E.g. to allow for an
      #   idempotency_key to be passed in the request headers, or for the
      #   api_key to be overwritten. See
      #   {APIOperations::Request.execute_resource_request}.
      def save(params = {}, opts = {})
        # We started unintentionally (sort of) allowing attributes sent to
        # +save+ to override values used during the update. So as not to break
        # the API, this makes that official here.
        update_attributes(params)

        # Now remove any parameters that look like object attributes.
        params = params.reject { |k, _| respond_to?(k) }

        values = serialize_params(self).merge(params)

        # Please note that id gets removed here our call to #url above has already
        # generated a uri for this object with an identifier baked in
        values.delete(:id)
        opts = Util.normalize_opts(opts)
        APIRequestor.active_requestor.execute_request_initialize_from(:post, save_url, :api, self,
                                                                      params: values,
                                                                      opts: RequestOptions.extract_opts_from_hash(opts),
                                                                      usage: ["save"])
      end
      extend Gem::Deprecate
      deprecate :save, "the `update` class method (for examples " \
                       "see https://github.com/stripe/stripe-ruby" \
                       "/wiki/Migration-guide-for-v8)", 2022, 11

      def self.included(base)
        # Set `metadata` as additive so that when it's set directly we remember
        # to clear keys that may have been previously set by sending empty
        # values for them.
        #
        # It's possible that not every object with `Save` has `metadata`, but
        # it's a close enough heuristic, and having this option set when there
        # is no `metadata` field is not harmful.
        base.additive_object_param(:metadata)

        base.extend(ClassMethods)
      end

      private def save_url
        # This switch essentially allows us "upsert"-like functionality. If the
        # API resource doesn't have an ID set (suggesting that it's new) and
        # its class responds to .create (which comes from
        # Stripe::APIOperations::Create), then use the URL to create a new
        # resource. Otherwise, generate a URL based on the object's identifier
        # for a normal update.
        if self[:id].nil? && self.class.respond_to?(:create)
          self.class.resource_url
        else
          resource_url
        end
      end
    end
  end
end
