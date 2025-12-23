# frozen_string_literal: true

module OAuth
  module Signature
    # Returns a list of available signature methods
    def self.available_methods
      @available_methods ||= {}
    end

    # Build a signature from a +request+.
    #
    # Raises UnknownSignatureMethod exception if the signature method is unknown.
    def self.build(request, options = {}, &block)
      request = OAuth::RequestProxy.proxy(request, options)
      klass = available_methods[
        (request.signature_method ||
        ((c = request.options[:consumer]) && c.options[:signature_method]) ||
        "").downcase]
      raise UnknownSignatureMethod, request.signature_method unless klass

      klass.new(request, options, &block)
    end

    # Sign a +request+
    def self.sign(request, options = {}, &block)
      build(request, options, &block).signature
    end

    # Verify the signature of +request+
    def self.verify(request, options = {}, &block)
      build(request, options, &block).verify
    end

    # Create the signature base string for +request+. This string is the normalized parameter information.
    #
    # See Also: {OAuth core spec version 1.0, section 9.1.1}[http://oauth.net/core/1.0#rfc.section.9.1.1]
    def self.signature_base_string(request, options = {}, &block)
      build(request, options, &block).signature_base_string
    end

    # Create the body hash for a request
    def self.body_hash(request, options = {}, &block)
      build(request, options, &block).body_hash
    end

    class UnknownSignatureMethod < RuntimeError; end
  end
end
