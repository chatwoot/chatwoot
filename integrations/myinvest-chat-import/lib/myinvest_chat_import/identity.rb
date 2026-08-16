# frozen_string_literal: true

module MyinvestChatImport
  class Identity
    def initialize(secret)
      raise ValidationError, 'hmac_key_too_short' unless secret.is_a?(String) && secret.bytesize >= 32

      @secret = secret
    end

    def for(bundle, type, external_id)
      value = ['myinvest-chat-import-v1', bundle.tenant_key, bundle.source_namespace, type, external_id].join("\0")
      OpenSSL::HMAC.hexdigest('SHA256', @secret, value)
    end

    def payload(record)
      Digest::SHA256.hexdigest(CanonicalJson.dump(record))
    end

    def tenant_lock(tenant_key)
      OpenSSL::HMAC.hexdigest('SHA256', @secret, ['myinvest-chat-import-v1', 'tenant_lock', tenant_key].join("\0"))
    end
  end
end
