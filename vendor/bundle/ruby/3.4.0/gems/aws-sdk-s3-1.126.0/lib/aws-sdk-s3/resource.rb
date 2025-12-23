# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3

  # This class provides a resource oriented interface for S3.
  # To create a resource object:
  #
  #     resource = Aws::S3::Resource.new(region: 'us-west-2')
  #
  # You can supply a client object with custom configuration that will be used for all resource operations.
  # If you do not pass `:client`, a default client will be constructed.
  #
  #     client = Aws::S3::Client.new(region: 'us-west-2')
  #     resource = Aws::S3::Resource.new(client: client)
  #
  class Resource

    # @param options ({})
    # @option options [Client] :client
    def initialize(options = {})
      @client = options[:client] || Client.new(options)
    end

    # @return [Client]
    def client
      @client
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   bucket = s3.create_bucket({
    #     acl: "private", # accepts private, public-read, public-read-write, authenticated-read
    #     bucket: "BucketName", # required
    #     create_bucket_configuration: {
    #       location_constraint: "af-south-1", # accepts af-south-1, ap-east-1, ap-northeast-1, ap-northeast-2, ap-northeast-3, ap-south-1, ap-southeast-1, ap-southeast-2, ap-southeast-3, ca-central-1, cn-north-1, cn-northwest-1, EU, eu-central-1, eu-north-1, eu-south-1, eu-west-1, eu-west-2, eu-west-3, me-south-1, sa-east-1, us-east-2, us-gov-east-1, us-gov-west-1, us-west-1, us-west-2
    #     },
    #     grant_full_control: "GrantFullControl",
    #     grant_read: "GrantRead",
    #     grant_read_acp: "GrantReadACP",
    #     grant_write: "GrantWrite",
    #     grant_write_acp: "GrantWriteACP",
    #     object_lock_enabled_for_bucket: false,
    #     object_ownership: "BucketOwnerPreferred", # accepts BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced
    #   })
    # @param [Hash] options ({})
    # @option options [String] :acl
    #   The canned ACL to apply to the bucket.
    # @option options [required, String] :bucket
    #   The name of the bucket to create.
    # @option options [Types::CreateBucketConfiguration] :create_bucket_configuration
    #   The configuration information for the bucket.
    # @option options [String] :grant_full_control
    #   Allows grantee the read, write, read ACP, and write ACP permissions on
    #   the bucket.
    # @option options [String] :grant_read
    #   Allows grantee to list the objects in the bucket.
    # @option options [String] :grant_read_acp
    #   Allows grantee to read the bucket ACL.
    # @option options [String] :grant_write
    #   Allows grantee to create new objects in the bucket.
    #
    #   For the bucket and object owners of existing objects, also allows
    #   deletions and overwrites of those objects.
    # @option options [String] :grant_write_acp
    #   Allows grantee to write the ACL for the applicable bucket.
    # @option options [Boolean] :object_lock_enabled_for_bucket
    #   Specifies whether you want S3 Object Lock to be enabled for the new
    #   bucket.
    # @option options [String] :object_ownership
    #   The container element for object ownership for a bucket's ownership
    #   controls.
    #
    #   BucketOwnerPreferred - Objects uploaded to the bucket change ownership
    #   to the bucket owner if the objects are uploaded with the
    #   `bucket-owner-full-control` canned ACL.
    #
    #   ObjectWriter - The uploading account will own the object if the object
    #   is uploaded with the `bucket-owner-full-control` canned ACL.
    #
    #   BucketOwnerEnforced - Access control lists (ACLs) are disabled and no
    #   longer affect permissions. The bucket owner automatically owns and has
    #   full control over every object in the bucket. The bucket only accepts
    #   PUT requests that don't specify an ACL or bucket owner full control
    #   ACLs, such as the `bucket-owner-full-control` canned ACL or an
    #   equivalent form of this ACL expressed in the XML format.
    # @return [Bucket]
    def create_bucket(options = {})
      Aws::Plugins::UserAgent.feature('resource') do
        @client.create_bucket(options)
      end
      Bucket.new(
        name: options[:bucket],
        client: @client
      )
    end

    # @!group Associations

    # @param [String] name
    # @return [Bucket]
    def bucket(name)
      Bucket.new(
        name: name,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   s3.buckets()
    # @param [Hash] options ({})
    # @return [Bucket::Collection]
    def buckets(options = {})
      batches = Enumerator.new do |y|
        batch = []
        resp = Aws::Plugins::UserAgent.feature('resource') do
          @client.list_buckets(options)
        end
        resp.data.buckets.each do |b|
          batch << Bucket.new(
            name: b.name,
            data: b,
            client: @client
          )
        end
        y.yield(batch)
      end
      Bucket::Collection.new(batches)
    end

  end
end
