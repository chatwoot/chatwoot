# frozen_string_literal: true

# Checks the reader privacy
#
module Dry
  module Initializer
    module Dispatchers
      module PrepareReader
        extend self

        def call(target: nil, reader: :public, **options)
          reader = case reader.to_s
                   when "false", ""                      then nil
                   when "true"                           then :public
                   when "public", "private", "protected" then reader.to_sym
                   else invalid_reader!(target, reader)
                   end

          {target:, reader:, **options}
        end

        private

        def invalid_reader!(target, _reader)
          raise ArgumentError, <<~MESSAGE
            Invalid setting for the ##{target} reader's privacy.
            Use the one of the following values for the `:reader` option:
            - 'public' (true) for the public reader (default)
            - 'private' for the private reader
            - 'protected' for the protected reader
            - nil (false) if no reader should be defined
          MESSAGE
        end
      end
    end
  end
end
