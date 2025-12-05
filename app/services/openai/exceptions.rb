module Openai::Exceptions
  class TranscriptionError < StandardError; end
  class RateLimitError < TranscriptionError; end
  class NetworkError < TranscriptionError; end
  class InvalidFileError < TranscriptionError; end
  class AuthenticationError < TranscriptionError; end
end
