FactoryBot.define do
  factory :account_saml_settings do
    account
    sso_url { 'https://idp.example.com/saml/sso' }
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
    idp_entity_id { 'https://idp.example.com/saml/metadata' }
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
  end
end
