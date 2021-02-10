FactoryBot.define do
  factory :data_import do
    data_type { 'contacts' }
    import_file { Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/contacts.csv'), 'text/csv') }
    account
  end
end
