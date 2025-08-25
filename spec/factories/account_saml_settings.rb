FactoryBot.define do
  factory :account_saml_settings do
    account
    enabled { false }
    sso_url { 'https://idp.example.com/saml/sso' }
    certificate_fingerprint { 'AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AB:CD:EF:12' }
    certificate { nil }
    sp_entity_id { 'chatwoot-test' }
    enforced_sso { false }
    attribute_mappings { {} }
    role_mappings { {} }

    trait :enabled do
      enabled { true }
    end

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
