# frozen_string_literal: true

module Aws
  module S3
    module Types
      # This error is not modeled.
      #
      # The bucket you are attempting to access must be addressed using the
      # specified endpoint. Please send all future requests to this endpoint.
      #
      # @!attribute [rw] endpoint
      #   @return [String]
      #
      # @!attribute [rw] bucket
      #   @return [String]
      #
      # @!attribute [rw] message
      #   @return [String]
      #
      class PermanentRedirect < Struct.new(:endpoint, :bucket, :region, :message)
        SENSITIVE = []
        include Aws::Structure
      end
    end
  end
end
