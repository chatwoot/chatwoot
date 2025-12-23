# frozen_string_literal: true

module Aws
  # Create and provide access to components of Amazon Resource Names (ARN).
  #
  # You can create an ARN and access it's components like the following:
  #
  #   arn = Aws::ARN.new(
  #     partition: 'aws',
  #     service: 's3',
  #     region: 'us-west-2',
  #     account_id: '12345678910',
  #     resource: 'foo/bar'
  #   )
  #   # => #<Aws::ARN ...>
  #
  #   arn.to_s
  #   # => "arn:aws:s3:us-west-2:12345678910:foo/bar"
  #
  #   arn.partition
  #   # => 'aws'
  #   arn.service
  #   # => 's3'
  #   arn.resource
  #   # => foo/bar
  #
  #   # Note: parser available for parsing resource details
  #   @see Aws::ARNParser#parse_resource
  #
  # @see https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#genref-arns
  class ARN

    # @param [Hash] options
    # @option options [String] :partition
    # @option options [String] :service
    # @option options [String] :region
    # @option options [String] :account_id
    # @option options [String] :resource
    def initialize(options = {})
      @partition = options[:partition]
      @service = options[:service]
      @region = options[:region]
      @account_id = options[:account_id]
      @resource = options[:resource]
    end

    # @return [String]
    attr_reader :partition

    # @return [String]
    attr_reader :service

    # @return [String]
    attr_reader :region

    # @return [String]
    attr_reader :account_id

    # @return [String]
    attr_reader :resource

    # Validates ARN contains non-empty required components.
    # Region and account_id can be optional.
    #
    # @return [Boolean]
    def valid?
      !partition.nil? && !partition.empty? &&
        !service.nil? && !service.empty? &&
        !resource.nil? && !resource.empty?
    end

    # Return the ARN format in string
    #
    # @return [String]
    def to_s
      "arn:#{partition}:#{service}:#{region}:#{account_id}:#{resource}"
    end

    # Return the ARN as a hash
    #
    # @return [Hash]
    def to_h
      {
        partition: @partition,
        service: @service,
        region: @region,
        account_id: @account_id,
        resource: @resource
      }
    end

    # Return the ARN as JSON
    #
    # @return [Hash]
    def as_json(_options = nil)
      {
        'partition' => @partition,
        'service' => @service,
        'region' => @region,
        'accountId' => @account_id,
        'resource' => @resource
      }
    end
  end
end
