module Facebook
  module Messenger
    # Base Facebook Messenger exception.
    class Error < StandardError; end

    # Base error class for Facebook API errors.
    class FacebookError < Error
      attr_reader :message
      attr_reader :type
      attr_reader :code
      attr_reader :subcode
      attr_reader :user_title
      attr_reader :user_msg
      attr_reader :fbtrace_id

      #
      # Constructor function.
      #
      # @param [Hash] error Hash containing information about error.
      #
      def initialize(error)
        @message = error['message']
        @type = error['type']
        @code = error['code']
        @subcode = error['error_subcode']
        @user_title = error['error_user_title']
        @user_msg = error['error_user_msg']
        @fbtrace_id = error['fbtrace_id']
      end

      #
      # Function to convert the error into string.
      #
      # @example
      #   Error_Object.to_s #=> "Invalid OAuth access token. (subcode: 1234567)"
      #
      # @return [String] String describing the error message
      #
      def to_s
        "#{@message} (subcode: #{subcode})"
      end
    end
  end
end
