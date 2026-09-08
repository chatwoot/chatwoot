FactoryBot.define do
  factory :data_import do
    data_type { 'contacts' }
    import_file { Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/contacts.csv'), 'text/csv') }
    account

    trait :intercom do
      data_type { 'intercom' }
      source_type { 'api' }
      source_provider { 'intercom' }
      import_types { %w[contacts conversations] }
      access_token { 'intercom-token' }
      import_file { nil }
    end

    trait :freshdesk do
      data_type { 'freshdesk' }
      source_type { 'api' }
      source_provider { 'freshdesk' }
      import_types { %w[contacts conversations] }
      access_token { 'freshdesk-api-key' }
      source_metadata { { domain: 'acme.freshdesk.com' } }
      import_file { nil }
    end
  end
end
