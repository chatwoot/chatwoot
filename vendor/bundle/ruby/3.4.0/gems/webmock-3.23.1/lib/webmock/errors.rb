# frozen_string_literal: true

module WebMock

  class NetConnectNotAllowedError < Exception
    def initialize(request_signature)
      request_signature_snippet = RequestSignatureSnippet.new(request_signature)
      text = [
        "Real HTTP connections are disabled. Unregistered request: #{request_signature}",
        request_signature_snippet.stubbing_instructions,
        request_signature_snippet.request_stubs,
        "="*60
      ].compact.join("\n\n")
      super(text)
    end

  end

end
