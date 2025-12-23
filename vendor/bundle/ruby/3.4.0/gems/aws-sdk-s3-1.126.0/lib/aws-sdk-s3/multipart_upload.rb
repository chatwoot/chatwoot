# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3

  class MultipartUpload

    extend Aws::Deprecations

    # @overload def initialize(bucket_name, object_key, id, options = {})
    #   @param [String] bucket_name
    #   @param [String] object_key
    #   @param [String] id
    #   @option options [Client] :client
    # @overload def initialize(options = {})
    #   @option options [required, String] :bucket_name
    #   @option options [required, String] :object_key
    #   @option options [required, String] :id
    #   @option options [Client] :client
    def initialize(*args)
      options = Hash === args.last ? args.pop.dup : {}
      @bucket_name = extract_bucket_name(args, options)
      @object_key = extract_object_key(args, options)
      @id = extract_id(args, options)
      @data = options.delete(:data)
      @client = options.delete(:client) || Client.new(options)
      @waiter_block_warned = false
    end

    # @!group Read-Only Attributes

    # @return [String]
    def bucket_name
      @bucket_name
    end

    # @return [String]
    def object_key
      @object_key
    end

    # @return [String]
    def id
      @id
    end

    # Upload ID that identifies the multipart upload.
    # @return [String]
    def upload_id
      data[:upload_id]
    end

    # Key of the object for which the multipart upload was initiated.
    # @return [String]
    def key
      data[:key]
    end

    # Date and time at which the multipart upload was initiated.
    # @return [Time]
    def initiated
      data[:initiated]
    end

    # The class of storage used to store the object.
    # @return [String]
    def storage_class
      data[:storage_class]
    end

    # Specifies the owner of the object that is part of the multipart
    # upload.
    # @return [Types::Owner]
    def owner
      data[:owner]
    end

    # Identifies who initiated the multipart upload.
    # @return [Types::Initiator]
    def initiator
      data[:initiator]
    end

    # The algorithm that was used to create a checksum of the object.
    # @return [String]
    def checksum_algorithm
      data[:checksum_algorithm]
    end

    # @!endgroup

    # @return [Client]
    def client
      @client
    end

    # @raise [NotImplementedError]
    # @api private
    def load
      msg = "#load is not implemented, data only available via enumeration"
      raise NotImplementedError, msg
    end
    alias :reload :load

    # @raise [NotImplementedError] Raises when {#data_loaded?} is `false`.
    # @return [Types::MultipartUpload]
    #   Returns the data for this {MultipartUpload}.
    def data
      load unless @data
      @data
    end

    # @return [Boolean]
    #   Returns `true` if this resource is loaded.  Accessing attributes or
    #   {#data} on an unloaded resource will trigger a call to {#load}.
    def data_loaded?
      !!@data
    end

    # @deprecated Use [Aws::S3::Client] #wait_until instead
    #
    # Waiter polls an API operation until a resource enters a desired
    # state.
    #
    # @note The waiting operation is performed on a copy. The original resource
    #   remains unchanged.
    #
    # ## Basic Usage
    #
    # Waiter will polls until it is successful, it fails by
    # entering a terminal state, or until a maximum number of attempts
    # are made.
    #
    #     # polls in a loop until condition is true
    #     resource.wait_until(options) {|resource| condition}
    #
    # ## Example
    #
    #     instance.wait_until(max_attempts:10, delay:5) do |instance|
    #       instance.state.name == 'running'
    #     end
    #
    # ## Configuration
    #
    # You can configure the maximum number of polling attempts, and the
    # delay (in seconds) between each polling attempt. The waiting condition is
    # set by passing a block to {#wait_until}:
    #
    #     # poll for ~25 seconds
    #     resource.wait_until(max_attempts:5,delay:5) {|resource|...}
    #
    # ## Callbacks
    #
    # You can be notified before each polling attempt and before each
    # delay. If you throw `:success` or `:failure` from these callbacks,
    # it will terminate the waiter.
    #
    #     started_at = Time.now
    #     # poll for 1 hour, instead of a number of attempts
    #     proc = Proc.new do |attempts, response|
    #       throw :failure if Time.now - started_at > 3600
    #     end
    #
    #       # disable max attempts
    #     instance.wait_until(before_wait:proc, max_attempts:nil) {...}
    #
    # ## Handling Errors
    #
    # When a waiter is successful, it returns the Resource. When a waiter
    # fails, it raises an error.
    #
    #     begin
    #       resource.wait_until(...)
    #     rescue Aws::Waiters::Errors::WaiterFailed
    #       # resource did not enter the desired state in time
    #     end
    #
    # @yieldparam [Resource] resource to be used in the waiting condition.
    #
    # @raise [Aws::Waiters::Errors::FailureStateError] Raised when the waiter
    #   terminates because the waiter has entered a state that it will not
    #   transition out of, preventing success.
    #
    #   yet successful.
    #
    # @raise [Aws::Waiters::Errors::UnexpectedError] Raised when an error is
    #   encountered while polling for a resource that is not expected.
    #
    # @raise [NotImplementedError] Raised when the resource does not
    #
    # @option options [Integer] :max_attempts (10) Maximum number of
    # attempts
    # @option options [Integer] :delay (10) Delay between each
    # attempt in seconds
    # @option options [Proc] :before_attempt (nil) Callback
    # invoked before each attempt
    # @option options [Proc] :before_wait (nil) Callback
    # invoked before each wait
    # @return [Resource] if the waiter was successful
    def wait_until(options = {}, &block)
      self_copy = self.dup
      attempts = 0
      options[:max_attempts] = 10 unless options.key?(:max_attempts)
      options[:delay] ||= 10
      options[:poller] = Proc.new do
        attempts += 1
        if block.call(self_copy)
          [:success, self_copy]
        else
          self_copy.reload unless attempts == options[:max_attempts]
          :retry
        end
      end
      Aws::Plugins::UserAgent.feature('resource') do
        Aws::Waiters::Waiter.new(options).wait({})
      end
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   multipart_upload.abort({
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    # @return [Types::AbortMultipartUploadOutput]
    def abort(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @object_key,
        upload_id: @id
      )
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.abort_multipart_upload(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   object = multipart_upload.complete({
    #     multipart_upload: {
    #       parts: [
    #         {
    #           etag: "ETag",
    #           checksum_crc32: "ChecksumCRC32",
    #           checksum_crc32c: "ChecksumCRC32C",
    #           checksum_sha1: "ChecksumSHA1",
    #           checksum_sha256: "ChecksumSHA256",
    #           part_number: 1,
    #         },
    #       ],
    #     },
    #     checksum_crc32: "ChecksumCRC32",
    #     checksum_crc32c: "ChecksumCRC32C",
    #     checksum_sha1: "ChecksumSHA1",
    #     checksum_sha256: "ChecksumSHA256",
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #   })
    # @param [Hash] options ({})
    # @option options [Types::CompletedMultipartUpload] :multipart_upload
    #   The container for the multipart upload request information.
    # @option options [String] :checksum_crc32
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32 checksum of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_crc32c
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 32-bit CRC32C checksum of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_sha1
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 160-bit SHA-1 digest of the object. For
    #   more information, see [Checking object integrity][1] in the *Amazon S3
    #   User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :checksum_sha256
    #   This header can be used as a data integrity check to verify that the
    #   data received is the same data that was originally sent. This header
    #   specifies the base64-encoded, 256-bit SHA-256 digest of the object.
    #   For more information, see [Checking object integrity][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    # @option options [String] :sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the object.
    #   This parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @option options [String] :sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This parameter
    #   is needed only when the object was created using a checksum algorithm.
    #   For more information, see [Protecting data using SSE-C keys][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @option options [String] :sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a checksum
    #   algorithm. For more information, see [Protecting data using SSE-C
    #   keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @return [Object]
    def complete(options = {})
      options = options.merge(
        bucket: @bucket_name,
        key: @object_key,
        upload_id: @id
      )
      Aws::Plugins::UserAgent.feature('resource') do
        @client.complete_multipart_upload(options)
      end
      Object.new(
        bucket_name: @bucket_name,
        key: @object_key,
        client: @client
      )
    end

    # @!group Associations

    # @return [Object]
    def object
      Object.new(
        bucket_name: @bucket_name,
        key: @object_key,
        client: @client
      )
    end

    # @param [String] part_number
    # @return [MultipartUploadPart]
    def part(part_number)
      MultipartUploadPart.new(
        bucket_name: @bucket_name,
        object_key: @object_key,
        multipart_upload_id: @id,
        part_number: part_number,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   parts = multipart_upload.parts({
    #     request_payer: "requester", # accepts requester
    #     expected_bucket_owner: "AccountId",
    #     sse_customer_algorithm: "SSECustomerAlgorithm",
    #     sse_customer_key: "SSECustomerKey",
    #     sse_customer_key_md5: "SSECustomerKeyMD5",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :request_payer
    #   Confirms that the requester knows that they will be charged for the
    #   request. Bucket owners need not specify this parameter in their
    #   requests. For information about downloading objects from Requester
    #   Pays buckets, see [Downloading Objects in Requester Pays Buckets][1]
    #   in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
    # @option options [String] :expected_bucket_owner
    #   The account ID of the expected bucket owner. If the bucket is owned by
    #   a different account, the request fails with the HTTP status code `403
    #   Forbidden` (access denied).
    # @option options [String] :sse_customer_algorithm
    #   The server-side encryption (SSE) algorithm used to encrypt the object.
    #   This parameter is needed only when the object was created using a
    #   checksum algorithm. For more information, see [Protecting data using
    #   SSE-C keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @option options [String] :sse_customer_key
    #   The server-side encryption (SSE) customer managed key. This parameter
    #   is needed only when the object was created using a checksum algorithm.
    #   For more information, see [Protecting data using SSE-C keys][1] in the
    #   *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @option options [String] :sse_customer_key_md5
    #   The MD5 server-side encryption (SSE) customer managed key. This
    #   parameter is needed only when the object was created using a checksum
    #   algorithm. For more information, see [Protecting data using SSE-C
    #   keys][1] in the *Amazon S3 User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/AmazonS3/latest/dev/ServerSideEncryptionCustomerKeys.html
    # @return [MultipartUploadPart::Collection]
    def parts(options = {})
      batches = Enumerator.new do |y|
        options = options.merge(
          bucket: @bucket_name,
          key: @object_key,
          upload_id: @id
        )
        resp = Aws::Plugins::UserAgent.feature('resource') do
          @client.list_parts(options)
        end
        resp.each_page do |page|
          batch = []
          page.data.parts.each do |p|
            batch << MultipartUploadPart.new(
              bucket_name: options[:bucket],
              object_key: options[:key],
              multipart_upload_id: options[:upload_id],
              part_number: p.part_number,
              data: p,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      MultipartUploadPart::Collection.new(batches)
    end

    # @deprecated
    # @api private
    def identifiers
      {
        bucket_name: @bucket_name,
        object_key: @object_key,
        id: @id
      }
    end
    deprecated(:identifiers)

    private

    def extract_bucket_name(args, options)
      value = args[0] || options.delete(:bucket_name)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :bucket_name"
      else
        msg = "expected :bucket_name to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    def extract_object_key(args, options)
      value = args[1] || options.delete(:object_key)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :object_key"
      else
        msg = "expected :object_key to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    def extract_id(args, options)
      value = args[2] || options.delete(:id)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :id"
      else
        msg = "expected :id to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    class Collection < Aws::Resources::Collection; end
  end
end
