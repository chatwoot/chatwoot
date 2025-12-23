# frozen_string_literal: true

module Aws
  module ARNParser
    # Parse a string with an ARN format into an {Aws::ARN} object.
    # `InvalidARNError` would be raised when encountering a parsing error or the
    # ARN object contains invalid components (nil/empty).
    #
    # @param [String] arn_str
    #
    # @return [Aws::ARN]
    # @see https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html#genref-arns
    def self.parse(arn_str)
      parts = arn_str.nil? ? [] : arn_str.split(':', 6)
      raise Aws::Errors::InvalidARNError if parts.size < 6

      # part[0] is "arn"
      arn = ARN.new(
        partition: parts[1],
        service: parts[2],
        region: parts[3],
        account_id: parts[4],
        resource: parts[5]
      )
      raise Aws::Errors::InvalidARNError unless arn.valid?

      arn
    end

    # Checks whether a String could be a ARN or not. An ARN starts with 'arn:'
    # and has at least 6 segments separated by a colon (:).
    #
    # @param [String] str
    #
    # @return [Boolean]
    def self.arn?(str)
      !str.nil? && str.start_with?('arn:') && str.scan(/:/).length >= 5
    end
  end
end
