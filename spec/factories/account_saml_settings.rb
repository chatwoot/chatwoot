FactoryBot.define do
  factory :account_saml_settings do
    account
    sso_url { 'https://idp.example.com/saml/sso' }
    certificate_fingerprint { nil }
    certificate do
      key = OpenSSL::PKey::RSA.new(2048)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = OpenSSL::X509::Name.parse('/C=US/ST=Test/L=Test/O=Test/CN=test.example.com')
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.zone.now
      cert.not_after = cert.not_before + (365 * 24 * 60 * 60)
      cert.sign(key, OpenSSL::Digest.new('SHA256'))
      cert.to_pem
    end
    sp_entity_id { 'chatwoot-test' }
    enforced_sso { false }
    attribute_mappings { {} }
    role_mappings { {} }

    trait :with_role_mappings do
      role_mappings do
        {
          'Administrators' => { 'role' => 1 },
          'Agents' => { 'role' => 0 },
          'Custom-Team' => { 'custom_role_id' => 5 }
        }
      end
    end

    trait :with_attribute_mappings do
      attribute_mappings do
        {
          'email' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
          'name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
          'first_name' => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname'
        }
      end
    end
  end
end
