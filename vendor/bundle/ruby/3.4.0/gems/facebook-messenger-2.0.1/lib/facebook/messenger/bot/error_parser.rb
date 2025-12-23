module Facebook
  module Messenger
    module Bot
      # Parses and raises Facebook response errors for the send API.
      class ErrorParser
        INTERNAL_ERROR_CODES = {
          1200 => []
        }.freeze

        ACCESS_TOKEN_ERROR_CODES = {
          190 => []
        }.freeze

        ACCOUNT_LINKING_ERROR_CODES = {
          10_303 => []
        }.freeze

        LIMIT_ERROR_CODES = {
          4 => [2_018_022],
          100 => [2_018_109],
          613 => [nil]
        }.freeze

        BAD_PARAMETER_ERROR_CODES = {
          100 => [nil, 2_018_001]
        }.freeze

        PERMISSION_ERROR_CODES = {
          10 => [2_018_065, 2_018_108],
          200 => [1_545_041, 2_018_028, 2_018_027, 2_018_021],
          230 => [nil]
        }.freeze

        class << self
          # Raise any errors in the given response.
          #
          # response - A HTTParty::Response object.
          #
          # Returns nil if no errors were found, otherwises raises appropriately
          def raise_errors_from(response)
            return unless response.key? 'error'

            error = response['error']

            error_code = error['code']
            error_subcode = error['error_subcode']

            raise_code_only_error(error_code, error) if error_subcode.nil?

            raise_code_subcode_error(error_code, error_subcode, error)

            # Default to unidentified error
            raise FacebookError, error
          end

          private

          def raise_code_only_error(error_code, args)
            raise InternalError, args       if internal_error?(error_code)
            raise AccessTokenError, args    if access_token_error?(error_code)
            raise AccountLinkingError, args if account_linking_error?(
              error_code
            )
          end

          def raise_code_subcode_error(error_code, error_subcode, args)
            raise LimitError, args        if limit_error?(error_code,
                                                          error_subcode)
            raise BadParameterError, args if bad_parameter_error?(error_code,
                                                                  error_subcode)
            raise PermissionError, args   if permission_error?(error_code,
                                                               error_subcode)
          end

          def internal_error?(error_code)
            INTERNAL_ERROR_CODES.key? error_code
          end

          def access_token_error?(error_code)
            ACCESS_TOKEN_ERROR_CODES.key? error_code
          end

          def account_linking_error?(error_code)
            ACCOUNT_LINKING_ERROR_CODES.key? error_code
          end

          def limit_error?(error_code, error_subcode)
            limit_errors = LIMIT_ERROR_CODES[error_code]
            return unless limit_errors

            limit_errors.include? error_subcode
          end

          def bad_parameter_error?(error_code, error_subcode)
            bad_parameter_errors = BAD_PARAMETER_ERROR_CODES[error_code]
            return unless bad_parameter_errors

            bad_parameter_errors.include? error_subcode
          end

          def permission_error?(error_code, error_subcode)
            permission_errors = PERMISSION_ERROR_CODES[error_code]
            return unless permission_errors

            permission_errors.include? error_subcode
          end
        end
      end
    end
  end
end
